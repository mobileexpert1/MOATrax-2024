//
//  AppDelegate.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import UIKit
import IQKeyboardManagerSwift
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initKeyboardConfig()
        initGoogleConfig()
        initLocalDatabase()

        initFacebookConfig(with: application, launchingOptions: launchOptions)
        
        
        return true
    }
    
    // MARK: - init iq keyboard
    
    func initKeyboardConfig() {
        IQKeyboardManager.shared.enable = true
    }
    
    // MARK: - init firebase and google signin
    
    func initGoogleConfig() {
        FirebaseApp.configure()
    }
    
    // MARK: - init local Database
    
    func initLocalDatabase() {
        UserDefaultsUtils.saveUserLoggedInValue(true, keyValue: UserProfileKeys.isMyMapsTab.rawValue)
        DBManager.createEditableCopyOfDatabaseIfNeeded()
        DBManager.shared.openConnection()
    }
    
    
    
    // MARK: - init facebook confi
    
    func initFacebookConfig(with application: UIApplication, launchingOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchingOptions)
    }
}

// MARK: - init open url config

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var handled: Bool
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            options: options
        )
    }
}
