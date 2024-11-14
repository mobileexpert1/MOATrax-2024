//
//  Constant.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation
import UIKit

let baseUrl = "https://services.myoutdooragent.com/api/" // Live Base Url
//let baseUrl = "https://datav2.myoutdooragent.com/api/" // Dev Base Url

enum AuthenticationEndPoints: String {
    case login = "account/Authorize"
    
    var url: URL {
        return URL(string: baseUrl + self.rawValue)!
    }
}

enum HomeEndPoints: String {
    case mapList = "property/mapfiles"
    
    var url: URL {
        return URL(string: baseUrl + self.rawValue)!
    }
}

struct MapDetailScreenConstant {
    
    static let AlertAttributeTitleStr = "attributedTitle"
    static let AlertAttributeMesgStr = "attributedMessage"
    static let AlertAttributeTitileTextColourStr = "titleTextColor"
    
    static let BlankStr = ""
    static let GibsonBFont = "gibson-bold"
    static let PleaseStr = "Please"
    static let AttensionStr = "Attention"
    static let EnterPDFNameStr = "Please Enter PDF Name"
    static let ListOfSavedTracks =  "My Tracks"
    static let ClearTrackingStr =  "Clear Tracking Points"
    static let EnterDifferentPDFNameStr = "Name Already Exists Please Enter A Different Name"

    
    static let OkStr = "Ok"
    static let SaveStr = "Save"
    static let CancelStr = "Cancel"
    static let TitleForTrackingSavePointsStr = "Do you want to save the map points?"
    
    static let NoStr = "No"
    static let YesStr = "Yes"
    
    static let OpenSettingStr = "Open Settings"
    static let LocationAccessStr = "Enable Location Access"
    static let LocationAccessMessageStr = "In order to be notified, please open this app's settings and set location access to 'Always'."
    static let LocationNewAccessMessageStr = "Please follow the below steps to enable location services:- "
    static let LocationStepsFollowStr = " Settings > Privacy > Location Services > MOA Trax > Always"
    
    static let MapSelectedImgNameStr = "ic_map"
    static let MapUnSelectedImgNameStr =  "ic_mapUn"
    
    static let LocationSelectedImgNameStr = "ic_locationTrackSelcted"
    static let LocationUnSelectedImgNameStr = "ic_locationTrackUn"    
}
