//
//  HURequest.swift
//  HttpUtility
//
//  Created by CodeCat15 on 1/31/21.
//  Copyright © 2021 CodeCat15. All rights reserved.
//

import Foundation

protocol Request {
    var url: URL { get set }
    var method: HUHttpMethods {get set}
}

public struct HURequest: Request {
    var url: URL
    var method: HUHttpMethods
    var requestBody: Data?

    init(withUrl url: URL, forHttpMethod method: HUHttpMethods, requestBody: Data? = nil) {
        self.url = url
        self.method = method
        self.requestBody = requestBody != nil ? requestBody : nil
    }
}

// the HUMedia will be part of next release
public struct HUMultiPartRequest: Request {
    var url: URL
    var method: HUHttpMethods
    var request: Encodable
    var media: [HUMedia]?
}

public struct HUMedia {
    let fileName: String // the name of the file that you want to save on the server
    let data: Data
    let mimeType: String // mime type of the file  image/jpeg or image/png etc
    let parameterName: String // api parameter name

    init(withMediaData data: Data, name: String, mimeType: HUMimeType, parameterName: String) {

        self.data = data
        self.fileName = name
        self.mimeType = mimeType.rawValue
        self.parameterName = parameterName
    }
}

public enum HUMimeType: String {
    // images mime type
    case gif = "image/gif"
    case jpeg = "image/jpeg"
    case pjpeg = "image/pjpeg"
    case png = "image/png"
    case svgxml = "image/svg+xml"
    case tiff = "image/tiff"
    case bmp = "image/bmp"

    // document mime type
    case csv = "text/csv"
    case wordDocument = "application/msword"
    case pdf = "application/pdf"
    case richTextFormat = "application/rtf"
    case plainText = "text/plain"
}

public enum HUStatusCode: Int, Decodable {
    case success = 200
    case badRequest = 400
    case unauthorised = 401
    case notFound = 404
    case expectationFailed = 417
}

public enum ContentType: String {
    case formUrlEncoded = "application/x-www-form-urlencoded"
    case json = "application/json"
}

public enum HUErrorMessage: String {
    case emptyResponse = "no response received"
}
