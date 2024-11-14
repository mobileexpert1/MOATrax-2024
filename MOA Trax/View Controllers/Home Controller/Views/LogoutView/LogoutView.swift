//
//  LogoutView.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.
//

import UIKit

protocol logOutViewDelegate: AnyObject {
    func delegateLogOutAcn()
    func delegateCancelAcn()
}

class LogoutView: UIView {
    
    @IBOutlet weak var viewLogout: UIView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnLogout: UIButton!
    
    @IBOutlet weak var logoutViewBottomConstraint: NSLayoutConstraint!
    
    weak var delegate: logOutViewDelegate?

    override func awakeFromNib() {
        initLayout()
    }
    func initLayout() {
        self.viewLogout.layer.cornerRadius = 16
        self.viewLogout.clipsToBounds = true
        self.viewLogout.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.btnCancel.layer.masksToBounds = true
        self.btnCancel.layer.cornerRadius = 8.0
        self.btnCancel.layer.borderColor = UIColor.black.cgColor
        self.btnCancel.layer.borderWidth = 1.0
        self.layoutIfNeeded()
    }
    
    @IBAction func acnLogOut() {
        self.delegate?.delegateLogOutAcn()
    }
    
    @IBAction func acnCancel() {
        self.delegate?.delegateCancelAcn()
    }
}
