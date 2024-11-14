//
//  MapFileExtension.swift
//  geolocate
//
//  Created by love on 08/10/21.
//

import Foundation

extension CDMapFile {
    func convertToMapFile() -> MapFile {
        var mapFile = MapFile.init(mapFile: mapFile ?? "", mapFileID: Int(mapFileID), mapFileName: mapFileName ?? "", mapInfoJSON: mapInfoJson ?? "")
        mapFile.mapFileLocalURL = mapFileLocalUrl
        return mapFile
    }
}
