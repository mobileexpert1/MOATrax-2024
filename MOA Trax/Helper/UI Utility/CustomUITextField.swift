//
//  File.swift
//  miniMealtimes
//
//  Created by Ayush Pathak on 14/11/19.
//  Copyright © 2019 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class CustomUITextField: UITextField {
    
    @IBInspectable var leftImage: UIImage? {
        didSet {
            updateLeftIconImage()
        }
    }
    
    @IBInspectable var rightImage: UIImage? {
        didSet {
            updateRightIconImage()
        }
    }
    
    @IBInspectable var leftPadding: CGFloat = 0
    @IBInspectable var rightPadding: CGFloat = 0
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var shadowColor: UIColor = .clear {
        didSet {
            self.layer.shadowColor = shadowColor.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            self.layer.shadowOpacity = shadowOpacity
        }
    }
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            self.layer.shadowRadius = shadowRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var placeholderColor: UIColor = UIColor.init(red: 178/255, green: 178/255, blue: 178/255, alpha: 1) {
        didSet {
            updatePlaceholder(with: placeholderColor)
        }
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
    }
    
    func updatePlaceholder(with color: UIColor) {
        if let placeholderText = self.placeholder {
            attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: color])
        }
    }
    func updateLeftIconImage() {
        if let image = leftImage {
            let imageView = UIImageView(frame: CGRect(x: 16, y: (self.frame.height-20)/2, width: 20, height: 20))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            
            let view = UIView()
            view.addSubview(imageView)
            view.frame = CGRect(x: 0, y: 0, width: self.frame.height, height: self.frame.height)
            leftView = view
            
            self.leftViewMode = UITextField.ViewMode.always
        } else {
            leftViewMode = UITextField.ViewMode.never
            leftView = nil
        }
    }
    func updateRightIconImage() {
        if let image = rightImage {
            let imageView = UIImageView(frame: CGRect(x: 16, y: (self.frame.height-20)/2, width: 20, height: 20))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            
            let view = UIView()
            view.addSubview(imageView)
            view.frame = CGRect(x: 0, y: 0, width: self.frame.height, height: self.frame.height)
            rightView = view
            
            self.rightViewMode = UITextField.ViewMode.always
        } else {
            rightViewMode = UITextField.ViewMode.never
            rightView = nil
        }
    }
}
