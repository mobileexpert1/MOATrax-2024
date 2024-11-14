//
//  LoginResource.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation

struct LoginResource {
    func loginUser(with request: LoginRequest, completion: @escaping (LoginResponse?, String?) -> Void) {
        
        let jsonEncoder = JSONEncoder()
        do {
            let requestBody = try jsonEncoder.encode(request)
            let loginRequest = HURequest.init(withUrl: AuthenticationEndPoints.login.url, forHttpMethod: .post, requestBody: requestBody)
            HttpUtility.shared.request(huRequest: loginRequest, resultType: LoginResponse.self) { response in
                switch response {
                case .success(let result):
                    completion(result, nil)
                case .failure(let error):
                    completion(nil, error.reason)
                }
            }
        } catch let error {
            completion(nil, error.localizedDescription)
        }
    }
}
