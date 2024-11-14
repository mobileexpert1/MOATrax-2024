//
//  UserDefaultUtility.swift
//  geolocate
//
//  Created by Appentus Technologies on 21/09/21.
//

import Foundation

class UserDefaultsUtils {
    class func setLogInDetailsToUserDefault(with data: LoginResult) {
        saveUserLoggedInValue(true, keyValue: UserProfileKeys.isLoggedIn.rawValue)
        UserDefaults.standard.setValue(data.email, forKey: UserProfileKeys.emailAddress.rawValue)
        UserDefaults.standard.setValue(data.userProfileID, forKey: UserProfileKeys.profileId.rawValue)
        UserDefaults.standard.setValue(data.authToken, forKey: UserProfileKeys.authenticationToken.rawValue)
        UserDefaults.standard.setValue(data.token, forKey: UserProfileKeys.token.rawValue)
        UserDefaults.standard.setValue(data.firstName, forKey: UserProfileKeys.firstName.rawValue)
        UserDefaults.standard.setValue(data.lastName, forKey: UserProfileKeys.lastName.rawValue)
        UserDefaults.standard.setValue(data.authenticationType, forKey: UserProfileKeys.authType.rawValue)        
    }
    
    class func saveSessionIdForLocalDatabase(_ sessionId: Int,keyValue:String) {
        UserDefaults.standard.setValue(sessionId, forKey: keyValue)
    }
    
    class func saveUserLoggedInValue(_ success: Bool,keyValue:String) {
        UserDefaults.standard.setValue(success, forKey: keyValue)
    }
    
    class func retriveUserLoggedInValue(keyValue:String) -> Bool {
        if let value = UserDefaults.standard.value(forKey: keyValue) as? Bool {
            return value
        }
        return false
    }
    
    class func retriveSessionIdForLocalDatabase(keyValue:String) -> Int {
        if let value = UserDefaults.standard.value(forKey: keyValue) as? Int {
            return value
        }
        return 0
    }
        
    class func saveRememberUserValue(_ success: Bool) {
        UserDefaults.standard.setValue(success, forKey: UserProfileKeys.rememberUser.rawValue)
    }
    
    class func retriveRememberUserValue() -> Bool {
        if let value = UserDefaults.standard.value(forKey: UserProfileKeys.rememberUser.rawValue) as? Bool {
            return value
        }
        return false
    }
    
    class func retriveStringValue(for key: UserProfileKeys) -> String? {
        if let value = UserDefaults.standard.value(forKey: key.rawValue) as? String {
            return value
        }
        return nil
    }
    
    class func saveValue(_ value: String, key: UserProfileKeys) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    class func logoutUser() {
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.profileId.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.userAccountType.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.token.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.authenticationToken.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.isLoggedIn.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.isSessionId.rawValue)
        UserDefaults.standard.removeObject(forKey: UserProfileKeys.isLoggedInMapScreen.rawValue)
        //For Reset All MapId Local Path
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        UserDefaults.standard.synchronize()
    }
}

enum UserProfileKeys: String {
    case firstName = "firstName"
    case lastName = "lastName"
    case emailAddress = "email"
    case profileId = "userProfileID"
    case userAccountType = "accountType"
    case token
    case authenticationToken = "authToken"
    case isLoggedIn = "isLogin"
    case isLoggedInMapScreen = "isLoginMapScreen"
    case isSessionId = "isSessionIdForLocal"
    case isMyMapsTab = "MyMapsTabKey"
    case rememberUser
    case password
    case authType
}
