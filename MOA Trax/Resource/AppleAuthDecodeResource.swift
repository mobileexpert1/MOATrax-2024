//
//  AppleAuthDecodeResurce.swift
//  geolocate
//
//  Created by love on 01/10/21.
//

import Foundation
import JWTDecode

struct AppleAuthDecodeResource {
    @available(iOS 13.0, *)
    func fetchUserDetails(with request: AppleAuthDecodeRequest, completion: (AppleAuthDecodeResponse?, String?) -> Void) {
        
        if let identityTokenData = request.credencials.identityToken, let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
            do {
                let jwtDecoder = try decode(jwt: identityTokenString)
                let jsonData =  try JSONSerialization.data(withJSONObject: jwtDecoder.body, options: [])
                
                let jsonDecoder = JSONDecoder()
                let decodedData = try jsonDecoder.decode(AppleAuthDecodeResponse.self, from: jsonData)
                
                completion(decodedData, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        }
    }
}
