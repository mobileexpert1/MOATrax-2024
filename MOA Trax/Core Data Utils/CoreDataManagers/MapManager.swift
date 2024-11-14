//
//  MapManager.swift
//  geolocate
//
//  Created by love on 12/10/21.
//

import Foundation

struct MapManager {
   
    private let mapDataRepository = MapListDataRepository()

    func createMap(map: MapFile) {
        mapDataRepository.create(record: map)
    }

    func fetchMap() -> [MapFile]? {
        return mapDataRepository.getAll()
    }

    func fetchMap(by mapId: String) -> MapFile? {
        return mapDataRepository.get(by: mapId)
    }

    func updateMap(map: MapFile) -> Bool {
        return mapDataRepository.update(record: map)
    }

    func deleteMap(by mapId: String) -> Bool {
        return mapDataRepository.delete(with: mapId)
    }
    func deleteAllMap() -> Bool {
        return mapDataRepository.deleteAllRecords()
    }
    
}
