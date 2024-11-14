//
//  MapInfoJson.swift
//  geolocate
//
//  Created by love on 02/11/21.
//

import Foundation

struct MapInfoJson: Decodable {
    let rasterXYsize: [Int]
    let projection: String
    let geotransform: [Double]
}
struct RasterData: Codable {
    let rasterXYsize: [Int]
    let projection: String
    let geotransform: [Double]
}
