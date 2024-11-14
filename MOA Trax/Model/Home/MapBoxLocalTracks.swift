//
//  MapBoxLocalTracks.swift
//  MOA Trax
//
//  Created by apple on 30/03/22.
//

import Foundation
// swiftlint:disable identifier_name
// swiftlint:disable line_length
class MapBoxLocalTracks: NSObject {
    var id: Int?
    var UserId: String?
    var SessionId: Int?
    var MapFile: String?
    var MapFileID: Int?
    var MapFileNameDefault: String?
    var MapFileNameLatest: String??
    var isNameLocalSave: Int?
    var MapInfoJSON: String?
    var MapFileLocalURL: String?
    
    
    class func mapBoxLocalData(info: AnyObject) -> MapBoxLocalTracks {
        let mapBoxLocalData = MapBoxLocalTracks()
        mapBoxLocalData.id                      = (info["Id"] as? Int)
        mapBoxLocalData.UserId                  = (info["UserId"] as? String)
        mapBoxLocalData.SessionId               = (info["SessionId"] as? Int)
        mapBoxLocalData.MapFile                 = (info["MapFile"] as? String)
        mapBoxLocalData.MapFileID               = (info["MapFileID"] as? Int)
        mapBoxLocalData.MapFileNameDefault      = (info["MapFileNameDefault"] as? String)
        mapBoxLocalData.MapFileNameLatest       = (info["MapFileNameLatest"] as? String)
        mapBoxLocalData.isNameLocalSave         = (info["isNameLocalSave"] as? Int)
        mapBoxLocalData.MapInfoJSON             = (info["MapInfoJSON"] as? String)
        mapBoxLocalData.MapFileLocalURL         = (info["MapFileLocalURL"] as? String)
        return mapBoxLocalData
    }
}
