//
//  MapListRepository.swift
//  geolocate
//
//  Created by love on 12/10/21.
//

import Foundation
import CoreData

protocol MapListRepository: BaseDataRepository {
    func deleteAllRecords() -> Bool
}

struct MapListDataRepository: MapListRepository {
    
    func deleteAllRecords() -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDMapFile")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try PersistentStorage.shared.context.execute(batchDeleteRequest)
            return true
        } catch {
            // Error Handling
            return false
        }
    }

    func create(record: MapFile) {
        let mapItem = CDMapFile(context: PersistentStorage.shared.context)
        mapItem.mapFile = record.mapFile
        mapItem.mapFileName = record.mapFileName
        mapItem.mapInfoJson = record.mapInfoJSON
        mapItem.mapFileID = Int64(record.mapFileID)
        PersistentStorage.shared.saveContext()
    }
    
    func getAll() -> [MapFile]? {
        let request: NSFetchRequest<CDMapFile> = CDMapFile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "mapFileID", ascending: true)]
        
        do {
            let result = try PersistentStorage.shared.context.fetch(request)
            var productList: [MapFile] = []
            
            result.forEach({ product in
                productList.append(product.convertToMapFile())
            })
            return productList

        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }
    
    func get(by recordId: String) -> MapFile? {
        let result = getCDMapFile(by: recordId)
        guard result != nil else {return nil}
        return result?.convertToMapFile()
    }
    
    func update(record: MapFile) -> Bool {
        
        guard let cdMapFile = getCDMapFile(by: "\(record.mapFileID)") else { return false }
        
        cdMapFile.mapFile = record.mapFile
        cdMapFile.mapFileName = record.mapFileName
        cdMapFile.mapInfoJson = record.mapInfoJSON
        cdMapFile.mapFileID = Int64(record.mapFileID)
        cdMapFile.mapFileLocalUrl = record.mapFileLocalURL
        PersistentStorage.shared.saveContext()
        return true
    }
    
    func delete(with recordId: String) -> Bool {
        let cdProduct = getCDMapFile(by: recordId)
        guard cdProduct != nil else {return false}
        
        PersistentStorage.shared.context.delete(cdProduct!)
        PersistentStorage.shared.saveContext()
        return true
    }
    
    private func getCDMapFile(by mapID: String) -> CDMapFile? {
        let fetchRequest = NSFetchRequest<CDMapFile>(entityName: "CDMapFile")
        let predicate = NSPredicate(format: "mapFileID == %i", Int64(mapID) ?? 0)
        
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
    
    typealias TypeVal = MapFile
    
}
