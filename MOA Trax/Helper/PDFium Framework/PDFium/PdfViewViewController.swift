//
//  PdfViewViewController.swift
//  GeoOffline
//
//  Created by love on 05/08/21.
//

import UIKit
import CGeometry

public protocol scrollViewActions {
    func scrollViewScroll(_ sender: UIScrollView)
}
public protocol SimplePDFViewControllerDelegate: AnyObject {
    func pdfZoomed(to scale: CGFloat)
    func pdfFinishedLoading()
}

extension SimplePDFViewControllerDelegate {
    func pdfZoomed(to scale: CGFloat) {}
    func pdfFinishedLoading() {}
}

public class PdfViewViewController: UIViewController {
    /// used for displaying the PDF and scrolling/zooming around
    public var scrollView: UIScrollView!
    /// add any views you'd like to have overlaid on the PDF in here
    public var overlayView: UIView!
    /// the content view of the scroll view, for your convenience (this is also the scroll view's `viewForZooming`)
    public var contentView: UIView!
    
    public var scrollDelegates: scrollViewActions?
    /// Simply assign a page to this property and the view will be updated accordingly.
    public var page: PDFPage! {
        didSet {
            loadViewIfNeeded()
            
            contentWidth.constant = page.size.width
            contentHeight.constant = page.size.height
            
            prepareFallback()
        }
    }
    
    public weak var delegate: SimplePDFViewControllerDelegate?
    
    private var fallbackView: UIImageView!
    private var renderView: UIImageView!
    private var contentWidth: NSLayoutConstraint!
    private var contentHeight: NSLayoutConstraint!
    
    /**
    The minimum time to wait between render tasks, so as not to use 100% of the cpu (granted, renders happen off-thread, but it's just not very energy-efficient).
    The default is 1/5, i.e. a maximum of 5 renders per second—this may seem low, but thanks to the fallback render in the background and the fact that renders also include some buffer of things that are just off-screen, it's really enough for most cases.
    */
    public var minRenderDelay: TimeInterval {
        get { renderScheduler.minDelay }
        set { renderScheduler.minDelay = newValue }
    }
    private let renderScheduler = TaskScheduler(
        on: DispatchQueue(label: "pdf rendering", qos: .userInitiated),
        minDelay: 1/5 // 5 fps target—it's honestly more than good enough
    )
    
    private var renderBitmap: PDFBitmap?
    private var fallbackResolution: CGSize!
    /// how much extra area to render around the borders (for smoother scrolling), in terms of the render size
    private let overrenderFraction: CGFloat = 0.1
    private var shouldResetZoom = true
    
    private static var defaultBackgroundColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }()
    
    /// The background color for the rendered page. Must be opaque for rendering to look right!
    public var backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) {
        didSet { forceRender() }
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func loadView() {
        let frame = CGRect(origin: .zero, size: .one)
        
        view = UIView(frame: frame)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.backgroundColor = Self.defaultBackgroundColor
        
        scrollView = UIScrollView(frame: frame)
        view.addSubview(scrollView)
        
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView = UIView(frame: frame)
        scrollView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentWidth = contentView.widthAnchor.constraint(equalToConstant: 1000)
        contentWidth.isActive = true
        contentHeight = contentView.heightAnchor.constraint(equalToConstant: 1000)
        contentHeight.isActive = true
        
        NSLayoutConstraint.activate([
            contentView.topAnchor     .constraint(equalTo: scrollView.topAnchor     ),
            contentView.bottomAnchor  .constraint(equalTo: scrollView.bottomAnchor  ),
            contentView.leadingAnchor .constraint(equalTo: scrollView.leadingAnchor ),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])
        
        fallbackView = UIImageView(frame: frame)
        contentView.addSubview(fallbackView)
        
        fallbackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        renderView = UIImageView(frame: frame)
        contentView.addSubview(renderView)
        
        overlayView = UIView(frame: frame)
        contentView.addSubview(overlayView)
        
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTapRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapRecognizer)
    }
    
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if let container = view.superview {
            view.frame = container.bounds
            shouldResetZoom = true
            view.setNeedsLayout()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
         
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // maintain zoom-to-fit if currently set
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            coordinator.animate(alongsideTransition: { _ in
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            })
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        renderBitmap = makeBitmap(size: scrollView.frame.size * (1 + 2 * overrenderFraction))
        
        let scrollableSize = scrollView.bounds.inset(by: scrollView.safeAreaInsets).size
        let scales = scrollableSize / page.size
        
        let scaleToFit = min(scales.width, scales.height)
        // set zoom scale bounds relatively to that
        scrollView.minimumZoomScale = scaleToFit * 1
        scrollView.maximumZoomScale = scaleToFit * 100
        
        let clampedScale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, scrollView.zoomScale))
        let scale = shouldResetZoom ? scaleToFit : clampedScale
        
        scrollView.setZoomScale(scale, animated: !shouldResetZoom)
        centerContentView()
        
        shouldResetZoom = false
    }
    
    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        
        if
            #available(iOS 12.0, *),
            traitCollection.userInterfaceStyle != previous?.userInterfaceStyle
        {
            forceRender()
        }
    }
    
    /// forces a render of everything visible, including the fallback render in the background
    public func forceRender() {
        guard page != nil else { return }
        
        enqueueRender()
        prepareFallback()
    }
    
    @objc private func doubleTapped(_ tapRecognizer: UITapGestureRecognizer) {
        guard tapRecognizer.state == .recognized else { return }
        
        let position = tapRecognizer.location(in: contentView)
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let size = contentView.bounds.size / 4
            scrollView.zoom(to: CGRect(origin: position - CGVector(size / 2), size: size), animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    /// renders a fallback image that's displayed when a part of the page isn't rendered yet; size is proportional to device screen size, which should be appropriate
    private func prepareFallback() {
        let screenBounds = UIScreen.main.bounds
        let targetSize = screenBounds.width * screenBounds.height * 3
        let pageSize = page.size.width * page.size.height
        let size = sqrt(targetSize / pageSize)
        let fallbackBitmap = makeBitmap(size: size * page.size)
        fallbackResolution = fallbackBitmap.size
        
        render(in: fallbackBitmap) { image in
            self.fallbackView.image = image
            self.delegate?.pdfFinishedLoading()
        }
    }
    
    /// makes a bitmap with the specified size in points (i.e. automatically scaled up on retina screens)
    private func makeBitmap(size: CGSize) -> PDFBitmap {
        UIGraphicsBeginImageContextWithOptions(size, false, 0) // false = not opaque; 0 = screen scale
        let context = UIGraphicsGetCurrentContext()!
        UIGraphicsEndImageContext() // yes, this is safe
        
        // normalize to (0, 1)
        context.scaleBy(x: size.width, y: size.height)
        // swiftlint:disable force_try
        return try! PDFBitmap(referencing: context)
        // swiftlint:enable force_try
    }
    
    private func centerContentView() {
        let contentSize = CGSize(
            width: contentWidth.constant,
            height: contentHeight.constant
        )
        let scaledSize = contentSize * scrollView.zoomScale // dirty but works
        
        let safeAreaInsets = scrollView.safeAreaInsets
        let scrollableSize = scrollView.bounds.inset(by: safeAreaInsets).size
        let offset = 0.5 * (scrollableSize - scaledSize).map { max(0, $0) }
        
        scrollView.contentInset = .init( // ugh
            top: safeAreaInsets.top + offset.height,
            left: safeAreaInsets.left + offset.width,
            bottom: safeAreaInsets.bottom + offset.height,
            right: safeAreaInsets.right + offset.width
        )
        
        // it looks like it's comparing the given insets to .zero and behaving differently (not actually zero!) if that's the case, so we have to be very close to but not actually equal to zero
        scrollView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: 0, right: 1e-9)
    }
    
    private func frameForRenderView() -> CGRect {
        let frame = contentView.convert(scrollView.frame, from: view)
        return CGRect(
            origin: frame.origin - CGVector(overrenderFraction * frame.size),
            size: frame.size * (1 + 2 * overrenderFraction)
        )
    }
    
    private func enqueueRender() {
        guard let renderBitmap = renderBitmap else { return }
        
        let newFrame = frameForRenderView()
        // bounds of the page in newFrame's coordinate system
        let pageBounds = CGRect(origin: -newFrame.origin, size: contentView.bounds.size)
        let renderBounds = pageBounds / newFrame.size
        
        // see if render would be higher-res than fallback
        let renderDensity = renderBitmap.size.width / newFrame.width
        let fallbackDensity = fallbackResolution.width / fallbackView.frame.width
        guard renderDensity > fallbackDensity else {
            renderView.image = nil
            return
        }
        
        render(in: renderBitmap, bounds: renderBounds) { [renderView] image in
            renderView!.image = image
            renderView!.frame = newFrame
        }
    }
    
    /// - Parameter bounds: the bounds of the page in normalized (0...1) coordinates (ULO); unit rect by default.
    /// - Parameter condition: a condition to evaluate when getting the opportunity to render asynchronously, to allow invalidating outdated tasks.
    private func render(
        in bitmap: PDFBitmap,
        bounds: CGRect = CGRect(origin: .zero, size: .one),
        completion: @escaping (UIImage) -> Void
    ) {
        let page = self.page!
        renderScheduler.enqueue {
            guard page === self.page else { return }
            
            // background color
            bitmap.context.clear(.init(origin: -100 * .zero, size: 201 * .one)) // .infinite doesn't work…
            bitmap.context.setFillColor(self.backgroundColor.cgColor)
            bitmap.context.fill(bounds)
            
            let renderBounds = bounds * bitmap.size
            
            page.render(in: bitmap, bounds: renderBounds)
            
            let image = UIImage(cgImage: bitmap.context.makeImage()!)
            
            DispatchQueue.main.async {
                guard page === self.page else { return }
                completion(image)
            }
        }
    }
}

extension PdfViewViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegates?.scrollViewScroll(scrollView)
        enqueueRender()
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContentView()
        enqueueRender()
        scrollDelegates?.scrollViewScroll(scrollView)

        delegate?.pdfZoomed(to: scrollView.zoomScale)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollDelegates?.scrollViewScroll(scrollView)

        enqueueRender()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        enqueueRender()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {

        enqueueRender()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

        enqueueRender()
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
}
