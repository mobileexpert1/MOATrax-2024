//
//  HttpUtility.swift
//  HttpUtility
//
//  Created by CodeCat15 on 5/17/20.
//  Copyright © 2020 CodeCat15. All rights reserved.
//

import Foundation

public class HttpUtility {
    public static let shared = HttpUtility()
    public var authenticationToken: String?
    public var customJsonDecoder: JSONDecoder?
    
    private init() {}
    
    public func request<T: Decodable>(huRequest: HURequest, resultType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        switch huRequest.method {
        case .get:
            getData(requestUrl: huRequest.url, resultType: resultType) { completionHandler($0)}
        case .post:
            postData(request: huRequest, resultType: resultType) { completionHandler($0)}
        case .put:
            putData(requestUrl: huRequest.url, resultType: resultType) { completionHandler($0)}
        case .delete:
            deleteData(requestUrl: huRequest.url, resultType: resultType) { completionHandler($0)}
        }
    }
    
    // MARK: - Multipart
    public func requestWithMultiPartFormData<T: Decodable>(multiPartRequest: HUMultiPartRequest, responseType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        postMultiPartFormData(request: multiPartRequest) { completionHandler($0) }
    }
    
    // MARK: - Private functions
    private func createJsonDecoder() -> JSONDecoder {
        let decoder =  customJsonDecoder != nil ? customJsonDecoder! : JSONDecoder()
        if customJsonDecoder == nil {
            decoder.dateDecodingStrategy = .iso8601
        }
        return decoder
    }
    
    private func createUrlRequest(requestUrl: URL) -> URLRequest {
        var urlRequest = URLRequest(url: requestUrl)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken = UserDefaultsUtils.retriveStringValue(for: UserProfileKeys.authenticationToken), authToken.isValidString {
            urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
    
    private func decodeJsonResponse<T: Decodable>(data: Data, responseType: T.Type) -> T? {
        let decoder = createJsonDecoder()
        do {
            return try decoder.decode(responseType, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            debugPrint(context)
        } catch let DecodingError.keyNotFound(key, context) {
            debugPrint("Key '\(key)' not found:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            debugPrint("Value '\(value)' not found:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context) {
            debugPrint("Type '\(type)' mismatch:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch {
            debugPrint("error: ", error)
        }
        return nil
    }
    
    // MARK: - GET Api
    private func getData<T: Decodable>(requestUrl: URL, resultType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        var urlRequest = self.createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = HUHttpMethods.get.rawValue
       
        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
    // MARK: - POST Api
    private func postData<T: Decodable>(request: HURequest, resultType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        var urlRequest = self.createUrlRequest(requestUrl: request.url)
        urlRequest.httpMethod = HUHttpMethods.post.rawValue
        urlRequest.httpBody = request.requestBody
        
        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
    private func postMultiPartFormData<T: Decodable>(request: HUMultiPartRequest, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        let boundary = "-----------------------------\(UUID().uuidString)"
        let lineBreak = "\r\n"
        var urlRequest = self.createUrlRequest(requestUrl: request.url)
        urlRequest.httpMethod = HUHttpMethods.post.rawValue
        urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var postBody = Data()
        
        if let requestDictionary = request.request.convertToDictionary() {
            requestDictionary.forEach({ (key, value) in
                if value != nil {
                    if let strValue = value.map({ String(describing: $0) }) {
                        postBody.append("--\(boundary + lineBreak)" .data(using: .utf8)!)
                        postBody.append("Content-Disposition: form-data; name=\"\(key)\" \(lineBreak + lineBreak)" .data(using: .utf8)!)
                        postBody.append("\(strValue + lineBreak)".data(using: .utf8)!)
                    }
                }
            })
            
            if let requestMedia = request.media {
                requestMedia.forEach({ (media) in
                    postBody.append("--\(boundary + lineBreak)" .data(using: .utf8)!)
                    postBody.append("Content-Disposition: form-data; name=\"\(media.parameterName)\"; filename=\"\(media.fileName)\" \(lineBreak + lineBreak)" .data(using: .utf8)!)
                    postBody.append("Content-Type: \(media.mimeType + lineBreak + lineBreak)" .data(using: .utf8)!)
                    postBody.append(media.data)
                    postBody.append(lineBreak .data(using: .utf8)!)
                })
            }
            
            postBody.append("--\(boundary)--\(lineBreak)" .data(using: .utf8)!)
            
            urlRequest.addValue("\(postBody.count)", forHTTPHeaderField: "Content-Length")
            urlRequest.httpBody = postBody
            
            performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
                DispatchQueue.main.async {
                    completionHandler(result)
                }
            }
        }
    }
    
    // MARK: - PUT Api
    private func putData<T: Decodable>(requestUrl: URL, resultType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        var urlRequest = self.createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = HUHttpMethods.put.rawValue
        
        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
    // MARK: - DELETE Api
    private func deleteData<T: Decodable>(requestUrl: URL, resultType: T.Type, completionHandler: @escaping (Result<T?, HUNetworkError>) -> Void) {
        var urlRequest = self.createUrlRequest(requestUrl: requestUrl)
        urlRequest.httpMethod = HUHttpMethods.delete.rawValue
        
        performOperation(requestUrl: urlRequest, responseType: T.self) { (result) in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
    // MARK: - Perform data task
    private func performOperation<T: Decodable>(requestUrl: URLRequest, responseType: T.Type, completionHandler:@escaping(Result<T?, HUNetworkError>) -> Void) {
        URLSession.shared.dataTask(with: requestUrl) { (data, httpUrlResponse, error) in
            
            let statusCode = (httpUrlResponse as? HTTPURLResponse)?.statusCode
            
            if let error = error {
                let networkError = HUNetworkError(withServerResponse: data, forRequestUrl: requestUrl.url!, withHttpBody: requestUrl.httpBody, errorMessage: error.localizedDescription, forStatusCode: statusCode ?? 500)
                completionHandler(.failure(networkError))
            } else {
                if let data = data {
                    if let response = self.decodeJsonResponse(data: data, responseType: responseType) {
                        completionHandler(.success(response))
                    } else {
                        completionHandler(.failure(HUNetworkError(withServerResponse: data, forRequestUrl: requestUrl.url!, withHttpBody: requestUrl.httpBody, errorMessage: "deocding error", forStatusCode: statusCode!)))
                    }
                } else {
                    completionHandler(.failure(HUNetworkError(withServerResponse: data, forRequestUrl: requestUrl.url!, withHttpBody: requestUrl.httpBody, errorMessage: error.debugDescription, forStatusCode: statusCode!)))
                }
            }
        }.resume()
    }
}
