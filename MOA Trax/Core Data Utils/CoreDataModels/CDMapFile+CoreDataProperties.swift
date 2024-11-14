//
//  CDMapFile+CoreDataProperties.swift
//  geolocate
//
//  Created by love on 12/10/21.
//
//

import Foundation
import CoreData

extension CDMapFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMapFile> {
        return NSFetchRequest<CDMapFile>(entityName: "CDMapFile")
    }

    @NSManaged public var mapFile: String?
    @NSManaged public var mapFileLocalUrl: String?
    @NSManaged public var mapFileName: String?
    @NSManaged public var mapInfoJson: String?
    @NSManaged public var mapFileID: Int64
    @NSManaged public var toProduct: CDProduct?

}
