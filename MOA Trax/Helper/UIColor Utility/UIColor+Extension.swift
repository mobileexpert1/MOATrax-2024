//
//  UIColor+Extension.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation
import UIKit

extension UIColor {
    
    public class var grediantOneColor: UIColor {
        return UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
    }
    
    public class var grediantTwoColor: UIColor {
        return UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.0)
    }
    
    public class var appGreenColor: UIColor {
        return UIColor(red: 44/255, green: 185/255, blue: 119/255, alpha: 1.0)
    }
    
    public class var btnDisableColor: UIColor {
        return UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1.0)
    }
    
    public class var btnEnableColor: UIColor {
        return UIColor(red: 30/255, green: 64/255, blue: 81/255, alpha: 1.0)
    }
    
}

extension UIColor {
    public convenience init?(hex: String) {
        let red, green, blue, alpha: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    alpha = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: red, green: green, blue: blue, alpha: alpha)
                    return
                }
            }
        }
        return nil
    }
}
