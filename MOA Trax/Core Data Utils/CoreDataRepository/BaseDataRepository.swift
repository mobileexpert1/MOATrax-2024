//
//  BaseDataRepository.swift
//  BaseDataRepository
//
//  Created by love on 23/09/21.
//  Copyright © 2021 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation

protocol BaseDataRepository {
    associatedtype TypeVal
    
    func create(record: TypeVal)
    func getAll() -> [TypeVal]?
    func get(by recordId: String) -> TypeVal?
    func update(record: TypeVal) -> Bool
    func delete(with recordId: String) -> Bool
}
