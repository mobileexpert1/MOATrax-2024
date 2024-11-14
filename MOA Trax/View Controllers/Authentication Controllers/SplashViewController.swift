//
//  SplashViewController.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import UIKit

class SplashViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(initNavigation), userInfo: nil, repeats: false)
        initNavigation()
    }
    
    @objc func initNavigation() {
        let userLoggedIn = UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isLoggedIn.rawValue)
        if !userLoggedIn {
            if let loginController = Storyboards.authentication.instance.instantiateViewController(withIdentifier: AuthenticationRoute.logInViewController.rawValue) as? LoginViewController {
                self.navigationController?.push(viewController: loginController, transitionType: .fade, duration: 0.3)
            }
        } else {
            if let homeController = Storyboards.home.instance.instantiateViewController(withIdentifier: HomeRoute.homeViewController.rawValue) as? HomeViewController {
                self.navigationController?.push(viewController: homeController, transitionType: .fade, duration: 0.3)
            }
        }
    }
    
}
