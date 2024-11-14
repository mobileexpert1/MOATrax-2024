//
//  AppleAuthDecodeResponse.swift
//  geolocate
//
//  Created by love on 01/10/21.
//

import Foundation

struct AppleAuthDecodeResponse: Decodable {
    let email: String
    let sub: String
}
