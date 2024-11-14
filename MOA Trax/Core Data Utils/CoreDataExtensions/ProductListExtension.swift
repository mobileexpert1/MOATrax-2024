//
//  ProductListExtension.swift
//  geolocate
//
//  Created by love on 08/10/21.
//

import Foundation

extension CDProduct {
    func convertToMapProduct() -> MapProduct {
        var mapItems = (self.toMapFile ?? []).array
        var mapConverted: [MapFile] = []
        
         mapItems = mapItems.sorted(by: { item1, item2 in
             return item1.mapFileID < item2.mapFileID  //return item1.mapFileID > item2.mapFileID -- to change the order of list on home view 
         })
        
        for mapItem in mapItems {
            mapConverted.append(mapItem.convertToMapFile())
        }
        
        return MapProduct.init(productName: productName ?? "", productNo: productNo ?? "", displayName: displayName ?? "", productID: Int(productID), mapFiles: mapConverted)
    }
}
