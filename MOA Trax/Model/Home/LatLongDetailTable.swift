//
//  LatLongDetailTable.swift
//  MOA Trax
//
//  Created by apple on 01/04/22.
//

import Foundation
// swiftlint:disable identifier_name
// swiftlint:disable line_length
class LatLongDetailTable: NSObject {
    var id: String?
    var UserId: String?
    var Latitude: Double?
    var Longitude: Double?
    var MapSessionId: Int?
    
    
    class func listOfMapLatLongDetails(info: AnyObject) -> LatLongDetailTable {
        let mapBoxLocalData = LatLongDetailTable()
        mapBoxLocalData.id                     = (info["Id"] as? String)
        mapBoxLocalData.UserId                 = (info["UserId"] as? String)
        mapBoxLocalData.MapSessionId           = (info["MapSessionId"] as? Int)
        mapBoxLocalData.Latitude               = (info["Latitude"] as? Double)
        mapBoxLocalData.Longitude              = (info["Longitude"] as? Double)
        return mapBoxLocalData
    }
}
