//
//  StoryBoard.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation
import UIKit

enum Storyboards: String {
    case authentication = "Authentication"
    case home = "Home"
   
    var instance: UIStoryboard {
        return UIStoryboard.init(name: self.rawValue, bundle: nil)
    }
}
