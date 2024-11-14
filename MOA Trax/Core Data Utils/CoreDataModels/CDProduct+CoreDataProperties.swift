//
//  CDProduct+CoreDataProperties.swift
//  geolocate
//
//  Created by love on 12/10/21.
//
//

import Foundation
import CoreData

extension CDProduct {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProduct> {
        return NSFetchRequest<CDProduct>(entityName: "CDProduct")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var productName: String?
    @NSManaged public var productNo: String?
    @NSManaged public var productID: Int64
    @NSManaged public var toMapFile: Set<CDMapFile>?

}

// MARK: Generated accessors for toMapFile
extension CDProduct {

    @objc(addToMapFileObject:)
    @NSManaged public func addToToMapFile(_ value: CDMapFile)

    @objc(removeToMapFileObject:)
    @NSManaged public func removeFromToMapFile(_ value: CDMapFile)

    @objc(addToMapFile:)
    @NSManaged public func addToToMapFile(_ values: Set<CDMapFile>)

    @objc(removeToMapFile:)
    @NSManaged public func removeFromToMapFile(_ values: Set<CDMapFile>)

}
