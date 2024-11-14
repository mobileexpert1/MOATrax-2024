//
//  ProductManager.swift
//  geolocate
//
//  Created by love on 12/10/21.
//

import Foundation

struct ProductManager {
   
    private let productDataRepository = ProductListDataRepository()

    func createProduct(product: MapProduct) {
        productDataRepository.create(record: product)
    }

    func fetchProduct() -> [MapProduct]? {
        return productDataRepository.getAll()
    }

    func fetchProduct(by productId: String) -> MapProduct? {
        return productDataRepository.get(by: productId)
    }

    func updateProduct(product: MapProduct) -> Bool {
        return productDataRepository.update(record: product)
    }

    func deleteProduct(by productId: String) -> Bool {
        return productDataRepository.delete(with: productId)
    }
    
    func deleteAllProducts() -> Bool {
        return productDataRepository.deleteAllRecords()
    }
    
    func insertUpdateProduct(with products: [MapProduct]) {
        productDataRepository.updateInsertRecords(with: products)
    }
}
