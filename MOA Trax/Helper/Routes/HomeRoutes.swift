//
//  HomeRoutes.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.
//

import Foundation
import UIKit

enum HomeRoute: String {
    static let storyBoard = Storyboards.home.instance
    
    case homeViewController = "HomeViewController"
    case mapPreviewViewController = "MapPreviewViewController"
    
    var controller: UIViewController {
        return HomeRoute.storyBoard.instantiateViewController(withIdentifier: self.rawValue)
    }

}
