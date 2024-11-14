//
//  Loader.swift
//  geolocate
//
//  Created by Appentus Technologies on 21/09/21.
//

import UIKit

class Loader {
    
    static let shared = Loader()
    
    private init () {
        initSpinner()
    }
    
    var spinnerView: UIView?
    var window = UIApplication.shared.windows.first
    
    let activityIndicator = { () -> UIActivityIndicatorView in
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView.init(style: .large)
        } else {
            return UIActivityIndicatorView.init()
        }
    }()
    
    func initSpinner() {
        spinnerView = UIView.init(frame: self.window?.bounds ?? .zero)
        spinnerView?.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        activityIndicator.center = spinnerView!.center
        
        spinnerView!.addSubview(activityIndicator)
        self.window?.addSubview(spinnerView!)
        self.spinnerView?.alpha = 0.0
    }
    
    func showSpinner() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.spinnerView?.alpha = 1.0
        }
    }
    
    func hideSpinner() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.spinnerView?.alpha = 0.0
        }
    }
    
}
