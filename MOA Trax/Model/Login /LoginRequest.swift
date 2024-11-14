//
//  LoginRequest.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation
import GoogleSignIn
struct LoginRequest: Encodable {
    let email: String
    let password: String
    let authenticationType: LoginType
    let authorizationKey: String?
    
    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case password = "Password"
        case authenticationType = "AuthenticationType"
        case authorizationKey = "AuthorizationKey"
    }
}

enum LoginType: String, Encodable {
    case orbis = "orbis"
    case apple = "Apple"
    case facebook = "Facebook"
    case google = "Google"
}
