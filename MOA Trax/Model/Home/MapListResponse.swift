//
//  MapList.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.0
//

import Foundation

// MARK: - Empty
struct MapListResponse: Decodable {
    let statusCode: HUStatusCode
    let message: String
    let model: [MapProduct]?
}

// MARK: - Model
struct MapProduct: Decodable {
    let productName, productNo, displayName: String?
    let productID: Int
    var mapFiles: [MapFile]?
}

// MARK: - MapFile
struct MapFile: Decodable {
    let mapFile: String
    let mapFileID: Int
    let mapFileName, mapInfoJSON: String?
    var mapFileLocalURL: String?
    var sessionIdLocal: Int?

    enum CodingKeys: String, CodingKey {
        case mapFile, mapFileName
        case mapInfoJSON = "mapInfoJson"
        case mapFileID,sessionIdLocal
    }
}
struct PDFCoordinateBounds {
    let xMin: Double
    let yMin: Double
    let xMax: Double
    let yMax: Double
}


struct LatLongCoordinates {
    var minX: Double  // minLatitude
    var minY: Double  // minLongitude
    var maxX: Double  // maxLatitude
    var maxY: Double   // maxLongitude
}
struct PdfBoundsResult {
    var coordinates: LatLongCoordinates
    var latitude: Double
    var longitude: Double
    var imageSize: CGSize
}
