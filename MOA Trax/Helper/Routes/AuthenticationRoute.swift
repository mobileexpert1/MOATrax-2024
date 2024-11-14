//
//  AuthenticationRoute.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation
import UIKit

enum AuthenticationRoute: String {
    static let storyBoard = Storyboards.authentication.instance
    
    case splashViewController = "SplashViewController"
    case logInViewController = "LoginViewController"
    
    var controller: UIViewController {
        return AuthenticationRoute.storyBoard.instantiateViewController(withIdentifier: self.rawValue)
    }

}
