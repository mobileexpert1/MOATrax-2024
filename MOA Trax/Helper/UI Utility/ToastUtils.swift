//
//  ToastUtils.swift
//  geolocate
//
//  Created by Appentus Technologies on 21/09/21.
//

import UIKit
import Toaster

class ToastUtils {
    
    static let shared = ToastUtils()
    
    private init() {
        configureToast()
    }
    
    // MARK: - Display Toast
    
    func showToast(with message: String) {
        Toast.init(text: message).show()
        
    }
    
    func configureToast() {
        ToastView.appearance().backgroundColor = UIColor.black
        ToastView.appearance().textColor = UIColor.white
        ToastView.appearance().font = UIFont(name: "Poppins-Regular", size: 16.0)
    }
    
}
