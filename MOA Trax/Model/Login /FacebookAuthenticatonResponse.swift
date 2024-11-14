//
//  FacebookAuthenticatonResponse.swift
//  Teesas
//
//  Created by love on 17/09/21.
//  Copyright © 2021 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation

struct FacebookAuthenticatonResponse: Decodable {
    let email: String
    let socialId: String
    let fullName: String
    let picture: FacebookPicture
    
    enum CodingKeys: String, CodingKey {
        case socialId = "id"
        case email
        case fullName = "name"
        case picture
    }
}

struct FacebookPicture: Decodable {
    let data: FacebookPictureData
}

struct FacebookPictureData: Decodable {
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "url"
    }
}
