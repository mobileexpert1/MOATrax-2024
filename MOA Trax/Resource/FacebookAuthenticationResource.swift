//
//  FacebookAuthenticationResource.swift
//  Teesas
//
//  Created by love on 17/09/21.
//  Copyright © 2021 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

struct FacebookAuthenticationResource {
    func fetchUser(completion: @escaping (FacebookAuthenticatonResponse?, String?) -> Void) {
        if AccessToken.current != nil {
            let parameter: [String: Any] = [
                "fields": "id,email,name,picture.width(480).height(480)"
            ]
            
            GraphRequest(graphPath: "me", parameters: parameter).start { _, result, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let resultData = try JSONSerialization.data(withJSONObject: result!, options: .prettyPrinted)
                        let resultDecoded = try jsonDecoder.decode(FacebookAuthenticatonResponse.self, from: resultData)
                        completion(resultDecoded, nil)
                    } catch {
                        completion(nil, error.localizedDescription)
                    }
                }
            }
        } else {
            completion(nil, "Facebook access token is invalid")
        }
    }
}
