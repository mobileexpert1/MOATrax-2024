//
//  PersistentStorage.swift
//  Teesas
//
//  Created by love on 18/09/21.
//  Copyright © 2021 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation
import CoreData

final class PersistentStorage {
    
    private init() { }
    static let shared = PersistentStorage()
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "MoaTrax")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var context = persistentContainer.viewContext
    // MARK: - Core Data Saving support
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetchManagedObject<T: NSManagedObject>(managedObject: T.Type) -> [T]? {
        do {
            guard let result = try PersistentStorage.shared.context.fetch(managedObject.fetchRequest()) as? [T] else {return nil}
            return result
            
        } catch let error {
            debugPrint(error)
        }
        return nil
    }
}
