//
//  MapPreviewViewController.swift
//  geolocate
//
//  Created by love on 13/10/21.
//

import UIKit
import PDFKit
//import GeoTiffDecoder
import CoreLocation
import MapboxStatic
// swiftlint:disable identifier_name
// swiftlint:disable line_length
// swiftlint:disable empty_count
protocol UpdateMainViewControllerLocalTracksValuesDelegate {
    func updateMainViewControllerLocalResponse(isBack:Bool)
    func checkNameExistOrNot(pdfName:String) -> Bool
}

class MapPreviewViewController: UIViewController {
    
    @IBOutlet weak var pdfTitleLbl: UILabel!
    @IBOutlet weak var currentCoordinateLbl: UILabel!
    @IBOutlet weak var pdfContainerView: UIView!
    
    var delegate: UpdateMainViewControllerLocalTracksValuesDelegate?
    var mapItem: MapFile?
    var isComeFromMapScreen = false
    var mapInfoJson: MapInfoJson?
    //var coordinates: Coordinates?
    var coordinates : CGRect?
    var coordinateObj : LatLongCoordinates?
    
    var pdfController: PdfViewViewController? {
        return self.children.compactMap({ $0 as? PdfViewViewController }).first
    }
    
    let currentmarkerImagView: UIImageView = {
        let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 18, height: 18))
        imageView.image = #imageLiteral(resourceName: "ic_currentLoc")
        return imageView
    }()
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    var localTempLocation: CLLocationCoordinate2D?
    var visibleScrollViewRect: CGRect?
    var zooomLevel: CGFloat?
    var trackingLocations: [CLLocationCoordinate2D] = []
    var trackingMarkers: [UIImageView] = []
    
    var isFirstLoad = true
    var isSecondLoad = true
    
    let mapSaveResource = MapSaveLocalResource()
    var countForSkipLocation = 0
    var distanceBetween = 0
    var previousLocation: CLLocation?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initPdfView()
        self.initMapData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        UserDefaultsUtils.saveUserLoggedInValue(true, keyValue: UserProfileKeys.isLoggedInMapScreen.rawValue)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func initMapData() {
        guard let mapItem = mapItem else {
            return
        }
        self.mapInfoJson = decodeMapInfo(with: mapItem.mapInfoJSON ?? "")
        
        guard let mapInfoJson = mapInfoJson else {
            return
        }
        
        
        let jsonString = mapItem.mapInfoJSON ?? ""
        if let result = fetchBoundsforPdf(from: jsonString) {
            self.coordinateObj = result
            self.fetchInitialPinCoordinates()
            self.initCurrentLocation()
        }
        
    }
    func initPdfView() {
        guard let mapFile = mapItem else { return }
        do {
            self.pdfTitleLbl.text = mapFile.mapFileName
            let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            if let path = paths.first {
                let fileURL = URL(fileURLWithPath: path).appendingPathComponent(mapFile.mapFileName ?? "")
                let document = try PDFDocument.init(at: fileURL)
                pdfController?.page = try document.page(0)
                pdfController?.scrollDelegates = self
                pdfController?.scrollView.layoutSubviews()
            }
        } catch {
            ToastUtils.shared.showToast(with: error.localizedDescription)
        }
    }
    
    func decodeMapInfo(with value: String) -> MapInfoJson? {
        do {
            guard let valueData = value.data(using: .utf8) else {
                return nil
            }
            let decodedResult = try JSONDecoder().decode(MapInfoJson.self, from: valueData)
            return decodedResult
        } catch {
            print("error: ", error)
        }
        return nil
    }
    
    @IBAction func zoomOutBtnAction(_ sender: UIButton) {
        guard let pdfController = pdfController else { return }
        pdfController.scrollView.setZoomScale(0.0, animated: true)
    }
    
    @IBAction func backBtnAction(_ sender: UIButton) {
        if isPresentOnCoordinates() {
            if distanceBetween != 0 {
                showAlertWhenUserClickBackButton(title: MapDetailScreenConstant.AttensionStr, message: MapDetailScreenConstant.TitleForTrackingSavePointsStr, isForSaveName: false, FirstButtonName: MapDetailScreenConstant.SaveStr, SecondButtonName: MapDetailScreenConstant.CancelStr)
            }else{
                self.navigationController?.popViewController(animated: true)
                UserDefaultsUtils.saveUserLoggedInValue(false, keyValue: UserProfileKeys.isLoggedInMapScreen.rawValue)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
            UserDefaultsUtils.saveUserLoggedInValue(false, keyValue: UserProfileKeys.isLoggedInMapScreen.rawValue)
        }
        locationManager.stopUpdatingLocation()
    }
}

extension MapPreviewViewController: scrollViewActions {
    
    func scrollViewScroll(_ sender: UIScrollView) {
        let visibleRect = CGRect.init(x: sender.contentOffset.x, y: sender.contentOffset.y, width: sender.contentSize.width*sender.zoomScale, height: sender.contentSize.height*sender.zoomScale)
        self.visibleScrollViewRect = visibleRect
        self.zooomLevel = sender.zoomScale
        if coordinateObj != nil {
            updatePinCoordinates(with: self.visibleScrollViewRect!, zoomScale: sender.zoomScale)
            if  isFirstLoad || isSecondLoad {
                self.getLocalPointsWithParticularSessionId()
            }
        }
    }
    
    func fetchInitialPinCoordinates() {
        guard let coordinates = coordinateObj else { return }
        
        let latitude = coordinates.maxX - (0.5 * (coordinates.maxX - coordinates.minX))
        let longitude = coordinates.minY + (0.5 * (coordinates.maxY - coordinates.minY))
        
        self.currentCoordinateLbl.text = "\(latitude)" + "," + "\(longitude)"
    }
    
    func updatePinCoordinates(with visibleRect: CGRect, zoomScale: CGFloat) {
        guard let coordinates = coordinateObj else { return }
        
        let xPos = (visibleRect.origin.x + (self.pdfContainerView.frame.width / 2)) / visibleRect.width
        let yPos = (visibleRect.origin.y + (self.pdfContainerView.frame.height / 2)) / visibleRect.height
        
        let xFactor: Double = Double(xPos * zoomScale)
        let yFactor: Double = Double(yPos * zoomScale)
        
        let latitude = -((yFactor * (coordinates.maxX - coordinates.minX)) - coordinates.maxX)
        let longitude = coordinates.minY + (xFactor * (coordinates.maxY - coordinates.minY))
        
        if isFirstLoad {
            isFirstLoad = false
        } else {
            if isSecondLoad {
                isSecondLoad = false
            } else {
                self.currentCoordinateLbl.text = "\(latitude)" + "," + "\(longitude)"
            }
        }
        
        if isPresentOnCoordinates() {
            updateTrackingMarker()
            updateMarkerVisiblityOnPdfView()
        } else {
            removeMarkerFromPdfView()
        }
    }
}

// MARK: - Location manager delagates and current location tracker

extension MapPreviewViewController: CLLocationManagerDelegate {
    
    func showAlertWhenUserDeclineTheLocationPermission() {
        let alertController = UIAlertController(title: MapDetailScreenConstant.BlankStr, message: MapDetailScreenConstant.BlankStr, preferredStyle: UIAlertController.Style.alert)
        let myString  = "\(MapDetailScreenConstant.LocationAccessStr)\n"
        var myMutableString = NSMutableAttributedString()
        myMutableString = NSMutableAttributedString(string: myString as String, attributes: [NSAttributedString.Key.font:UIFont(name: MapDetailScreenConstant.GibsonBFont, size: 15.0)!])
        myMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location:0,length:myString.count))
        alertController.setValue(myMutableString, forKey: MapDetailScreenConstant.AlertAttributeTitleStr)
        
        let message  = "\n\(MapDetailScreenConstant.LocationNewAccessMessageStr) \(MapDetailScreenConstant.LocationStepsFollowStr)"
        var messageMutableString = NSMutableAttributedString()
        messageMutableString = NSMutableAttributedString(string: message as String, attributes: [NSAttributedString.Key.font:UIFont(name:MapDetailScreenConstant.GibsonBFont, size: 13.0)!])
        messageMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: NSRange(location:0,length:61))
        messageMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location:61,length:55))
        alertController.setValue(messageMutableString, forKey: MapDetailScreenConstant.AlertAttributeMesgStr)
        let action = UIAlertAction(title: MapDetailScreenConstant.OkStr, style: UIAlertAction.Style.default, handler: nil)
        action.setValue(UIColor.black, forKey: MapDetailScreenConstant.AlertAttributeTitileTextColourStr)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager,didChangeAuthorization status: CLAuthorizationStatus ) {
        print("Locaiton Permission:- \(CLLocationManager.authorizationStatus())")
        switch CLLocationManager.authorizationStatus() {
        case .denied,.restricted:
            showAlertWhenUserDeclineTheLocationPermission()
        case .authorizedAlways,.authorizedWhenInUse:
            print("Locaiton Authorized")
            initCurrentLocation()
        case .notDetermined:
            print("Locaiton Not Determined")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break;
        }
    }
    
    func initCurrentLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.currentLocation = locValue
        if isPresentOnCoordinates() {
            print("Called didUpdateLocations ")
            let userLoggedIn = UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isLoggedInMapScreen.rawValue)
            if userLoggedIn {
                print("In Class Called didUpdateLocations ")
                addTrackingMarker()
                updateMarkerVisiblityOnPdfView()
                getCurrentLocMakerOutSideFrameOrNot()
            }else{
                print("Out Class Called didUpdateLocations ")
            }
        } else {
            removeMarkerFromPdfView()
        }
    }
    
    func getCurrentLocMakerOutSideFrameOrNot() {
        var visibleRect = CGRect.init(x: 0, y: 0, width: 0, height: 0)
        visibleRect.origin = pdfController!.scrollView.contentOffset
        visibleRect.size = pdfController!.scrollView.bounds.size
        
        print("Pdf Controller ScrollView ","\ny = ",visibleRect.origin.y,"\nx = ",visibleRect.origin.x,"\nCurrent Marker View ","\ny = ",currentmarkerImagView.frame.origin.y,"\nx = ",currentmarkerImagView.frame.origin.x)
        
        if !visibleRect.intersects(currentmarkerImagView.frame) {
            print("Outer View")
            guard let locValue: CLLocationCoordinate2D = self.currentLocation else { return }
            guard let coordinates = coordinateObj else { return }
            
            let yFactor = (locValue.longitude - coordinates.minY) / (coordinates.maxY - coordinates.minY)
            let xFactor = (coordinates.maxX - locValue.latitude) / (coordinates.maxX - coordinates.minX)
            
            var positionX: Double = 0.0
            var positionY: Double = 0.0
            
            positionX = (yFactor*Double(visibleScrollViewRect!.size.width))/Double(self.zooomLevel!)
            positionY = (xFactor*Double(visibleScrollViewRect!.size.height))/Double(self.zooomLevel!)
            
            if visibleScrollViewRect!.size.width <  1.0 {
                positionX = (yFactor*Double(18))*Double(self.zooomLevel!)
                positionY = (xFactor*Double(18))*Double(self.zooomLevel!)
            }
            let centerPoint = CGPoint(x: positionX-207, y: positionY-328)
            //let centerPoint = CGPoint(x: positionX , y: positionY )
            UIView.animate(withDuration: 2, animations: {
                self.pdfController!.scrollView.setContentOffset(centerPoint, animated: false)
                self.pdfController!.scrollView.setZoomScale(self.pdfController!.scrollView.zoomScale/2, animated: false)
            })
            
            // Without Custom Set X and Y points
            // let centerPoint = CGPoint(x: positionX , y: positionY )
            // UIView.animate(withDuration: 3, animations: {
            // self.pdfController!.scrollView.setContentOffset(centerPoint, animated: false)
            // self.pdfController!.scrollView.setZoomScale(self.pdfController!.scrollView.zoomScale/2, animated: false)
            // })
                    }
    } 
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            
        }
    func isPresentOnCoordinates() -> Bool {
        
        guard let coordinates = coordinateObj else { return false }
        
        let bottom = coordinates.minY
        let left = coordinates.minX
        let top = coordinates.maxY
        let right = coordinates.maxX
        
        if checkLocationInBoundss(top: top, right: right, bottom: bottom, left: left) {
            return true
        } else {
            return false
        }
    }
        
        func checkLocationInBoundss(top: Double, right: Double, bottom: Double, left: Double) -> Bool {
            guard let locValue: CLLocationCoordinate2D = self.currentLocation else { return false }
            return locValue.latitude > left && locValue.latitude < right && locValue.longitude < top && locValue.longitude > bottom
        }
    
        func updateMarkerVisiblityOnPdfView() {
            guard let locValue: CLLocationCoordinate2D = self.currentLocation else { return }
            guard let coordinates = coordinateObj else { return }
            
            let yFactor = (locValue.longitude - coordinates.minY) / (coordinates.maxY - coordinates.minY)
            let xFactor = (coordinates.maxX - locValue.latitude) / (coordinates.maxX - coordinates.minX)
            //
            var positionX: Double = 0.0
            var positionY: Double = 0.0
            
            positionX = (yFactor*Double(visibleScrollViewRect!.size.width))/Double(self.zooomLevel!)
            positionY = (xFactor*Double(visibleScrollViewRect!.size.height))/Double(self.zooomLevel!)
            
            if visibleScrollViewRect!.size.width < 1.0 {
                positionX = (yFactor*Double(18))*Double(self.zooomLevel!)
                positionY = (xFactor*Double(18))*Double(self.zooomLevel!)
            }
            
            var indexOfExistingImageView: Int?
            
            for index in 0..<pdfController!.scrollView.subviews.count {
                if let imageview = pdfController!.scrollView.subviews[index] as? UIImageView {
                    if imageview.image == currentmarkerImagView.image {
                        indexOfExistingImageView = index
                    }
                }
            }
            
            if let imageSubviewIndex = indexOfExistingImageView {
                if let imageViewReference = pdfController!.scrollView.subviews[imageSubviewIndex] as? UIImageView {
                    // update postion
                    imageViewReference.center = .init(x: positionX, y: positionY)
                    self.pdfController!.scrollView.bringSubviewToFront(imageViewReference)
                }
            } else {
                self.currentmarkerImagView.center = .init(x: positionX, y: positionY)
                self.pdfController!.scrollView.addSubview(currentmarkerImagView)
                self.pdfController!.scrollView.bringSubviewToFront(currentmarkerImagView)
            }
        } 
  
    func removeMarkerFromPdfView() {
        for subview in pdfController!.contentView.subviews where subview == currentmarkerImagView {
            subview.removeFromSuperview()
        }
    }
        func addTrackingMarker() {
               guard let locValue: CLLocationCoordinate2D = self.currentLocation else { return }
               guard let coordinates = coordinateObj else { return }

               let yFactor = (locValue.longitude - coordinates.minY) / (coordinates.maxY - coordinates.minY)
               let xFactor = (coordinates.maxX - locValue.latitude) / (coordinates.maxX - coordinates.minX)
               
               var positionX: Double = 0.0
               var positionY: Double = 0.0
               
               positionX = (yFactor*Double(visibleScrollViewRect!.size.width))/Double(self.zooomLevel!)
               positionY = (xFactor*Double(visibleScrollViewRect!.size.height))/Double(self.zooomLevel!)
               
               if visibleScrollViewRect!.size.width < 1.0 {
                   positionX = (yFactor*Double(8.0))*Double(self.zooomLevel!)
                   positionY = (xFactor*Double(8.0))*Double(self.zooomLevel!)
               }
            
               let trackingMarkerImagView: UIImageView = {
                   let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
                   imageView.image =  #imageLiteral(resourceName: "ic_track")
                   return imageView
               }()
               
               self.pdfController!.scrollView.addSubview(trackingMarkerImagView)
               trackingMarkerImagView.center = .init(x: positionX, y: positionY)
               self.trackingLocations.append(locValue)
               guard let lastMarker = self.pdfController!.scrollView.subviews.last as? UIImageView else { return }
               self.trackingMarkers.append(lastMarker)
            
            mapSaveResource.getRecordAllLocalTracks(isComeFromMapScreen:true,SessionId:  returnSessionId(isGet: true)) { [self] responseArray, responsseStatus in
                let getDistnceMthdResopnse = getDistanceBetweenTwoLocationWhenUserMove(currentLocation: CLLocationCoordinate2D(latitude: self.currentLocation!.latitude, longitude: self.currentLocation!.longitude))
                if getDistnceMthdResopnse.0 {
                    if responseArray.count > 0 {
                        self.mapSaveResource.insertRecordWithLatestNameInLatLongTbl(SessionId:   returnSessionId(isGet: true), mapFileID: mapItem!.mapFileID, latitude: self.currentLocation!.latitude, longitude: self.currentLocation!.longitude,distance:getDistnceMthdResopnse.1) { response in }
                    } else {
                        self.mapSaveResource.insertRecordWithLatestName(SessionId:   returnSessionId(isGet: true), mapFile: mapItem!.mapFile, mapFileID: mapItem!.mapFileID, mapFileName: mapItem!.mapFileName ?? MapDetailScreenConstant.BlankStr, latestName: MapDetailScreenConstant.BlankStr,mapInfoJSON:mapItem!.mapInfoJSON!, CreatedTimeStamp: "\(NSDate().timeIntervalSince1970)") { response in }
                    }
                }
            }
            updateMarkerVisiblityOnPdfView()
        }
        
        
    func getDistanceBetweenTwoLocationWhenUserMove(currentLocation:CLLocationCoordinate2D) -> (Bool,Int) {
        var returnStatusInRangeOrNot = false
        var returnDistance = 0
        if previousLocation == nil {
            previousLocation  = CLLocation(latitude:  currentLocation.latitude, longitude: currentLocation.longitude)
        }
        
        let currentLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let previousLocation1 = CLLocation(latitude: previousLocation!.coordinate.latitude, longitude: previousLocation!.coordinate.longitude)
        
        if currentLocation.coordinate.latitude != previousLocation1.coordinate.latitude && currentLocation.coordinate.longitude != previousLocation1.coordinate.longitude {
            returnDistance = Int(currentLocation.distance(from: previousLocation1).rounded())
            if returnDistance > 1 {
                returnStatusInRangeOrNot = true
                previousLocation  = currentLocation
                distanceBetween = returnDistance
            }
        }
        return (returnStatusInRangeOrNot,returnDistance)
    }
    func updateTrackingMarker() {
        for index in 0..<trackingLocations.count {
            guard let coordinates = coordinateObj else { return }
            
            let locValue = trackingLocations[index]
            let yFactor = (locValue.longitude - coordinates.minY) / (coordinates.maxY - coordinates.minY)
            let xFactor = (coordinates.maxX - locValue.latitude) / (coordinates.maxX - coordinates.minX)
            
            var positionX: Double = 0.0
            var positionY: Double = 0.0
            
            positionX = (yFactor*Double(visibleScrollViewRect!.size.width))/Double(self.zooomLevel!)
            positionY = (xFactor*Double(visibleScrollViewRect!.size.height))/Double(self.zooomLevel!)
            
            if visibleScrollViewRect!.size.width < 1.0 {
                positionX = (yFactor*Double(8.0))*Double(self.zooomLevel!)
                positionY = (xFactor*Double(8.0))*Double(self.zooomLevel!)
            }
            self.trackingMarkers[index].center = .init(x: positionX, y: positionY)
        }
    }

}
extension MapPreviewViewController {
    
    func returnSessionId(isGet:Bool) -> Int {
        var useSessionId = 0
        useSessionId = UserDefaultsUtils.retriveSessionIdForLocalDatabase(keyValue: UserProfileKeys.isSessionId.rawValue)
        if !isGet {
            UserDefaultsUtils.saveSessionIdForLocalDatabase(useSessionId + 1, keyValue: UserProfileKeys.isSessionId.rawValue)
            useSessionId = UserDefaultsUtils.retriveSessionIdForLocalDatabase(keyValue: UserProfileKeys.isSessionId.rawValue)
        }
        print("userSessionId = ",useSessionId)
        return useSessionId
    }
    
    func addMarkerForPath(indexValuelat:Double,indexValuelong:Double) {
        localTempLocation = CLLocationCoordinate2D(latitude: indexValuelat, longitude: indexValuelong)
        guard let locValue: CLLocationCoordinate2D = self.localTempLocation else { return }
        guard let coordinates = coordinateObj else { return }
        
        let yFactor = (locValue.longitude - coordinates.minY) / (coordinates.maxY - coordinates.minY)
        let xFactor = (coordinates.maxX - locValue.latitude) / (coordinates.maxX - coordinates.minX)
        
        var positionX: Double = 0.0
        var positionY: Double = 0.0
        
        positionX = (yFactor*Double(visibleScrollViewRect!.size.width))/Double(self.zooomLevel!)
        positionY = (xFactor*Double(visibleScrollViewRect!.size.height))/Double(self.zooomLevel!)
        
        if visibleScrollViewRect!.size.width < 1.0 {
            positionX = (yFactor*Double(8.0))*Double(self.zooomLevel!)
            positionY = (xFactor*Double(8.0))*Double(self.zooomLevel!)
        }
        
        let trackingMarkerImagView: UIImageView = {
            let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 10, height: 10))
            imageView.image =  #imageLiteral(resourceName: "ic_trackAlready")
            return imageView
        }()
        
        self.pdfController!.scrollView.addSubview(trackingMarkerImagView)
        trackingMarkerImagView.center = .init(x: positionX, y: positionY)
        self.trackingLocations.append(locValue)
        guard let lastMarker = self.pdfController!.scrollView.subviews.last as? UIImageView else { return }
        self.trackingMarkers.append(lastMarker)
    }
    func showAlertWhenUserClickBackButton(title:String,message:String,isForSaveName:Bool,FirstButtonName:String,SecondButtonName:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        if isForSaveName {
            alert.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = MapDetailScreenConstant.EnterPDFNameStr.replacingOccurrences(of: MapDetailScreenConstant.PleaseStr, with: MapDetailScreenConstant.BlankStr)
            }}
        
        alert.addAction(UIAlertAction(title: FirstButtonName, style: UIAlertAction.Style.default, handler: { actionResponse in
            if FirstButtonName == MapDetailScreenConstant.SaveStr {
                self.showAlertWhenUserClickBackButton(title: MapDetailScreenConstant.BlankStr, message: MapDetailScreenConstant.EnterPDFNameStr.replacingOccurrences(of: MapDetailScreenConstant.PleaseStr, with: MapDetailScreenConstant.BlankStr), isForSaveName: true, FirstButtonName: MapDetailScreenConstant.YesStr, SecondButtonName: MapDetailScreenConstant.NoStr)
            }else if FirstButtonName == MapDetailScreenConstant.YesStr {
                let textField = alert.textFields![0]
                if textField.text ==  MapDetailScreenConstant.BlankStr {
                    ToastUtils.shared.showToast(with: MapDetailScreenConstant.EnterPDFNameStr)
                }else{
                    let checkAlreadyExistName = self.delegate?.checkNameExistOrNot(pdfName: textField.text!)
                    if checkAlreadyExistName != nil {
                        if checkAlreadyExistName! {
                            ToastUtils.shared.showToast(with: MapDetailScreenConstant.EnterDifferentPDFNameStr)
                        }else{
                            self.mapSaveResource.updateRecordWithLatestName(latestName: textField.text!, SessionId:  self.returnSessionId(isGet: true)) { response in
                                if response {
                                    self.dismissView(isComeFromSaveAlert: true)
                                }
                            }
                        }
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: SecondButtonName, style: UIAlertAction.Style.destructive, handler: { actionResponse in
            if SecondButtonName == MapDetailScreenConstant.CancelStr {
                self.mapSaveResource.deleteRecordWithLatestName(comeFromMapScreen: true, SessionId:  self.returnSessionId(isGet: true)) { response
                    in
                    if response {
                        ToastUtils.shared.showToast(with: MapDetailScreenConstant.ClearTrackingStr)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now()+2.5) {
                        self.dismissView(isComeFromSaveAlert: false)
                    }
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func getLocalPointsWithParticularSessionId(){
        if isComeFromMapScreen {
            if mapItem!.sessionIdLocal != nil {
                mapSaveResource.getAllRecordWithParticularSessionId(SessionId: mapItem!.sessionIdLocal!) { responseArry, responseStatus in
                    for i in 0..<responseArry.count{
                        let mapFileInfo = responseArry[i] as? LatLongDetailTable
                        self.addMarkerForPath(indexValuelat: mapFileInfo!.Latitude!, indexValuelong: mapFileInfo!.Longitude!)
                    }
                }
            }
        }
    }
    
    func dismissView(isComeFromSaveAlert:Bool){
        UserDefaultsUtils.saveUserLoggedInValue(false, keyValue: UserProfileKeys.isLoggedInMapScreen.rawValue)
        if isComeFromSaveAlert {
            self.delegate?.updateMainViewControllerLocalResponse(isBack: true)
        }
        let _ = returnSessionId(isGet: false)
        self.navigationController?.popViewController(animated: true)
    }
}

extension MapPreviewViewController{
    // MARK: - Fetch pdf Bounds
    // Here we create our function to calculate minX, minY, maX and maxY  value from projection string
       func fetchBoundsforPdf(from jsonString: String) -> LatLongCoordinates? {
           // Convert JSON string to Data
           guard let jsonData = jsonString.data(using: .utf8) else {
               print("Failed to convert string to data.")
               return nil
           }
           // Decode JSON
           let decoder = JSONDecoder()
           do {
               let coordinates: LatLongCoordinates
               let rasterData = try decoder.decode(RasterData.self, from: jsonData)
               let projection = rasterData.projection
               // Extract size and geotransform values
               let width = rasterData.rasterXYsize[0]
               let height = rasterData.rasterXYsize[1]
               let geotransform = rasterData.geotransform
               let pixelWidth = geotransform[1] // Pixel size in X
               let pixelHeight = -geotransform[5] // Pixel size in Y (negative)
               let minX = geotransform[0] // Upper left X
               let maxX = minX + Double(width) * pixelWidth
               let maxY = geotransform[3] // Upper left Y
               let minY = maxY - Double(height) * pixelHeight
               
               // Determine the projection type and transform coordinates
               
               if projection.contains("WGS_1984_Web_Mercator") {
                   let minXLatitudeCoordinate = projectedToLatLong(x: minX, y: minY).latitude
                   let minYLongitudeCoordinate = projectedToLatLong(x: minX, y: minY).longitude
                   let maxXLatitudeCoordinate = projectedToLatLong(x: maxX, y: maxY).latitude
                   let maxYLongitudeCoordinate = projectedToLatLong(x: maxX, y: maxY).longitude
                   coordinates = LatLongCoordinates(
                       minX: minXLatitudeCoordinate,
                       minY: minYLongitudeCoordinate,
                       maxX: maxXLatitudeCoordinate,
                       maxY: maxYLongitudeCoordinate
                   )
               } else if projection.contains("NAD83 / UTM zone") {
                   let zone = extractUtmZone(from: projection)
                   let minCoordinates = convertNAD83UTMToLatLong(x: minX, y: maxY, utmZone: zone)
                   let maxCoordinates = convertNAD83UTMToLatLong(x: maxX, y: minY, utmZone: zone)
                   coordinates = LatLongCoordinates(
                       minX: minCoordinates.minX,
                       minY: minCoordinates.minY,
                       maxX: maxCoordinates.maxX,
                       maxY: maxCoordinates.maxY
                   )
               } else {
                   print("Unsupported projection type: \(projection)")
                   return nil
               }
               return coordinates
           } catch {
               print("Error decoding JSON: \(error)")
               return nil
           }
       }
   
   // MARK: - Projected to Latitude and Longitude when the projection is type of WGS_1984_Web_Mercator
    
       func projectedToLatLong(x: Double, y: Double) -> CLLocationCoordinate2D {
           let rMajor = 6378137.0 // Major radius of the Earth in meters
              // Calculate longitude
              let lon = (x / rMajor) * 180.0 / Double.pi
              // Calculate latitude
              let lat = 180.0 / Double.pi * (Double.pi / 2 - 2 * atan(exp(-y / rMajor)))
              return CLLocationCoordinate2D(latitude: lat, longitude: lon)
       }
    // MARK: - Projected to Latitude and Longitude when the projection is type of NAD83 / UTM zone
       func convertNAD83UTMToLatLong(x: Double, y: Double, utmZone: Int) -> LatLongCoordinates {
           let k0: Double = 0.9996
           let a: Double = 6378137.0 // Semi-major axis of WGS84
           let e: Double = 0.081819190842622 // Eccentricity of WGS84
           let e1sq: Double = 0.006739496742276 // e' squared
           
           // Calculate M
           let M: Double = y / k0
           
           // Calculate latitude
           let mu: Double = M / (a * (1.0 - pow(e, 2) / 4.0 - 3.0 * pow(e, 4) / 64.0 - 5.0 * pow(e, 6) / 256.0))
           let phi1Rad: Double = mu + (3.0 * e1sq / 2.0 - 27.0 * pow(e1sq, 3) / 32.0) * sin(2.0 * mu) +
           (21.0 * pow(e1sq, 2) / 16.0 - 55.0 * pow(e1sq, 4) / 32.0) * sin(4.0 * mu) +
           (151.0 * pow(e1sq, 3) / 96.0) * sin(6.0 * mu)
           
           let latitude = phi1Rad * (180.0 / .pi)
           
           // Calculate longitude
           let N: Double = a / sqrt(1.0 - pow(e * sin(phi1Rad), 2))
           let T: Double = pow(tan(phi1Rad), 2)
           let C: Double = e1sq * pow(cos(phi1Rad), 2)
           let A: Double = (x - 500000.0) / (N * k0)
           
           let longitude = (Double(utmZone) * 6.0 - 183.0) + (A - (1 + 2 * T + C) * pow(A, 3) / 6 +
                                                              (5 - T + 9 * C + 4 * pow(C, 2)) * pow(A, 5) / 120) * (180.0 / .pi)
           
           // Return the coordinates
           return LatLongCoordinates(minX: latitude, minY: longitude, maxX: latitude, maxY: longitude)
       }
   

    // MARK: - Exteract the Time Zone
    func extractUtmZone(from projection: String) -> Int {
        // Simple extraction logic for UTM zone, assuming the format is known
        let components = projection.components(separatedBy: "zone")
        if components.count > 1, let zoneString = components[1].prefix(3).split(separator: "N").first {
            return Int(zoneString) ?? 0
        }
        return 0
    }
    
}
