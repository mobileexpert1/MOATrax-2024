//
//  ProductListDataRepository.swift
//  geolocate
//
//  Created by love on 08/10/21.
//

import Foundation
import CoreData

protocol ProductListRepository: BaseDataRepository {
    func deleteAllRecords() -> Bool
    func updateInsertRecords(with products: [MapProduct])
}

struct ProductListDataRepository: ProductListRepository {
    
    static let mapListRepository = MapListDataRepository()
    
    func updateInsertRecords(with products: [MapProduct]) {
        for product in products {
            if self.get(by: "\(product.productID)") != nil {
                _ = self.update(record: product)
            } else {
                self.create(record: product)
            }
        }
        
        // remove not existing old products
        
        if let allProducts = getAll() {
            for product in allProducts {
                if (products.firstIndex(where: {$0.productID == product.productID}) == nil) {
                    _ = self.delete(with: "\(product.productID)")
                }
            }
        }
        
        // remove non existing map files
        
        var currentMapFiles: [MapFile] = []
        
        products.forEach { product in
            currentMapFiles.append(contentsOf: product.mapFiles ?? [])
        }
        
        let dbExistingMapData: [MapFile] = ProductListDataRepository.mapListRepository.getAll() ?? []

        dbExistingMapData.forEach { map in
            if (currentMapFiles.firstIndex(where: {$0.mapFileID == map.mapFileID}) == nil) {
                _ = ProductListDataRepository.mapListRepository.delete(with: "\(map.mapFileID)")
            }
        }
    }
 
    func deleteAllRecords() -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDProduct")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try PersistentStorage.shared.context.execute(batchDeleteRequest)
            return true
        } catch {
            // Error Handling
            return false
        }
    }
    
    func create(record: MapProduct) {
        let cdProduct = CDProduct(context: PersistentStorage.shared.context)
        cdProduct.productName = record.productName
        cdProduct.productNo = record.productNo
        cdProduct.displayName = record.displayName
        cdProduct.productID = Int64(record.productID)
        
        var mapFiles: Set<CDMapFile> = []
        
        if let mapFileList = record.mapFiles {
            mapFileList.forEach { mapFile in
                let mapItem = CDMapFile(context: PersistentStorage.shared.context)
                mapItem.mapFile = mapFile.mapFile
                mapItem.mapFileName = mapFile.mapFileName
                mapItem.mapInfoJson = mapFile.mapInfoJSON
                mapItem.mapFileID = Int64(mapFile.mapFileID)
                mapFiles.insert(mapItem)
            }
            cdProduct.toMapFile = mapFiles
        }
        PersistentStorage.shared.saveContext()
    }
    
    func getAll() -> [MapProduct]? {
        let result = PersistentStorage.shared.fetchManagedObject(managedObject: CDProduct.self)
        var productList: [MapProduct] = []
        
        result?.forEach({ product in
            productList.append(product.convertToMapProduct())
        })
        return productList
    }
    
    func get(by recordId: String) -> MapProduct? {
        let result = getCDProduct(by: recordId)
        guard result != nil else {return nil}
        return result?.convertToMapProduct()
    }
    
    func update(record: MapProduct) -> Bool {
        let cdProduct = getCDProduct(by: "\(record.productID)")
        guard cdProduct != nil else { return false }
        
        cdProduct?.productName = record.productName
        cdProduct?.displayName = record.displayName
        cdProduct?.productNo = record.productNo
        cdProduct?.productID = Int64(record.productID)
        
        var updatedFileList: Set<CDMapFile> = []
        let mapFileList = record.mapFiles ?? []
        
        if let previousRecords = cdProduct?.toMapFile {
            for item in mapFileList {
                if let existingRecord = previousRecords.first(where: {$0.mapFileID == item.mapFileID}) {
                    existingRecord.mapFile = item.mapFile
                    existingRecord.mapFileName = item.mapFileName
                    existingRecord.mapInfoJson = item.mapInfoJSON
                    if existingRecord.mapFile != item.mapFile {
                        existingRecord.mapFileLocalUrl = nil
                    }
                    updatedFileList.insert(existingRecord)
                } else {
                    let mapItem = CDMapFile(context: PersistentStorage.shared.context)
                    mapItem.mapFile = item.mapFile
                    mapItem.mapFileName = item.mapFileName
                    mapItem.mapInfoJson = item.mapInfoJSON
                    mapItem.mapFileID = Int64(item.mapFileID)
                    mapItem.mapFileLocalUrl = nil
                    updatedFileList.insert(mapItem)
                }
            }
        }
        
        cdProduct?.toMapFile = updatedFileList
        
        PersistentStorage.shared.saveContext()
        return true
    }
    
    func delete(with recordId: String) -> Bool {
        let cdProduct = getCDProduct(by: recordId)
        guard cdProduct != nil else {return false}
        
        PersistentStorage.shared.context.delete(cdProduct!)
        PersistentStorage.shared.saveContext()
        return true
    }
    
    private func getCDProduct(by productId: String) -> CDProduct? {
        let fetchRequest = NSFetchRequest<CDProduct>(entityName: "CDProduct")
        let predicate = NSPredicate(format: "productID == %i", Int64(productId) ?? 0)
        
        fetchRequest.predicate = predicate
        
        do {
            let result = try PersistentStorage.shared.context.fetch(fetchRequest).first
            guard result != nil else {return nil}
            return result
        } catch let error {
            debugPrint(error)
        }
        return nil
    }
    
    typealias TypeVal = MapProduct
    
}
