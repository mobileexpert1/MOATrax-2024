//
//  LoginResponse.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation

struct LoginResponse: Decodable {
    var statusCode: HUStatusCode
    var message: String?
    var model: LoginResult?
}

// MARK: - Model
struct LoginResult: Decodable {
    var userProfileID, userAccountID: Int?
    var firstName, lastName, streetAddress, city: String?
    var street, zip, phone: String?
    var isUserUnlisted, isEmailVerified: Bool?
    var email: String?
    var getNotifications: Bool?
    var authenticationType, message, token, authToken: String?
    var dateCreated, dateLastLogin: String?
    var accountType: Int?
    var modelDescription, name: String?
    var status: Int?
    
    enum CodingKeys: String, CodingKey {
        case userProfileID, userAccountID, firstName, lastName, streetAddress, city, zip, phone, isEmailVerified, email, getNotifications, authenticationType, message, token, authToken, dateCreated, dateLastLogin, accountType
        case isUserUnlisted = "isBlacklisted"
        case street = "st"
        case modelDescription = "description"
        case name, status
    }
}
