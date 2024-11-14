//
//  AppleAuthDecodeRequest.swift
//  geolocate
//
//  Created by love on 01/10/21.
//

import Foundation
import AuthenticationServices

@available(iOS 13.0, *)
struct AppleAuthDecodeRequest {
    let credencials: ASAuthorizationAppleIDCredential
}
