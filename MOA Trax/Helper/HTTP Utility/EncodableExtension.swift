//
//  EncodableExtension.swift
//  HttpUtility
//
//  Created by CodeCat15 on 5/31/20.
//  Copyright © 2020 CodeCat15. All rights reserved.
//

import Foundation

extension Encodable {
    func convertToQueryStringUrl(urlString: String) -> URL? {
        
        if var components = URLComponents(string: urlString) {
            if let requestDictionary = convertToDictionary() {
                var queryItems: [URLQueryItem] = []
                requestDictionary.forEach({ (key, value) in
                    if let value = value {
                        let strValue = "\(value)"
                        queryItems.append(URLQueryItem(name: key, value: strValue))
                    }
                })
                components.queryItems = queryItems
                return components.url!
            }
        }
        
        debugPrint("convertToQueryStringUrl => Error => Conversion failed, please make sure to pass a valid urlString and try again")
        
        return nil
    }
    
    func convertToDictionary() -> [String: Any?]? {
        do {
            let encoder = try JSONEncoder().encode(self)
            let result = (try? JSONSerialization.jsonObject(with: encoder, options: .allowFragments)).flatMap { $0 as? [String: Any?] }
            
            return result
            
        } catch let error {
            debugPrint(error)
        }
        return nil
    }
    
    func convertToUrlEncoded() -> Data? {
        if let dataDict = self.convertToDictionary() {
            let queryString = queryStringParamsToString(dataDict as [String: Any])
            let data = queryString.data(using: String.Encoding.utf8)
            return data
        }
        return nil
    }
    
    func queryStringParamsToString(_ dictionary: [String: Any]) -> String {
        return dictionary
            .map({(key, value) in "\(key)=\(value)"})
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    }
}
