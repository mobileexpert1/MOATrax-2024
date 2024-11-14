//
//  MapSaveLocalResource.swift
//  MOA Trax
//
//  Created by apple on 30/03/22.
//

import Foundation
// swiftlint:disable identifier_name
// swiftlint:disable line_length
// swiftlint:disable empty_count
struct MapSaveLocalResource {
    
    static var userName =  (UserDefaultsUtils.retriveStringValue(for: .firstName) ?? "") + " " + (UserDefaultsUtils.retriveStringValue(for: .lastName) ?? "")
    
    func insertRecordWithLatestName(SessionId:Int,mapFile:String, mapFileID:Int, mapFileName:String, latestName:String, mapInfoJSON:String, CreatedTimeStamp:String,completion: @escaping (Bool) -> Void) {
        let insertQuery = "INSERT INTO MapDetailsTbl (UserId,SessionId,MapFile, MapFileID, MapFileNameDefault,MapFileNameLatest,isNameLocalSave,MapInfoJSON,CreatedTimeStamp) VALUES ('\(MapSaveLocalResource.userName)',\(SessionId),'\(mapFile)',\(mapFileID), '\(mapFileName)', '\("")', \(0),'\(mapInfoJSON)','\(CreatedTimeStamp)')"
        DBManager.shared.insertRecord(query: insertQuery) { response in
            print("MapDetailsTbl Insert Query = ",insertQuery,"Response = ",response)
            if response {
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    func insertRecordWithLatestNameInLatLongTbl(SessionId:Int, mapFileID:Int, latitude:Double, longitude:Double, distance:Int, completion: @escaping (Bool) -> Void) {
        let insertQuery = "INSERT INTO LatLongDetailTable (UserId,MapSessionId,Latitude, Longitude,Distance) VALUES ('\(MapSaveLocalResource.userName)',\(SessionId),\(latitude),\(longitude),\(distance))"
        print("Insert Query = ",insertQuery)
        DBManager.shared.insertRecord(query: insertQuery) { response in
            print("LatLongDetailTable Insert Query = ",insertQuery,"Response = ",response)
            if response {
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    func updateRecordWithLatestName(latestName:String, SessionId:Int, completion: @escaping (Bool) -> Void) {
        let updateQuery = "UPDATE MapDetailsTbl SET MapFileNameLatest = '\(latestName)', isNameLocalSave = 1 WHERE MapFileNameLatest = '' AND isNameLocalSave = 0 AND UserId = '\(MapSaveLocalResource.userName)' AND SessionId = \(SessionId)"
        DBManager.shared.updateRecord(query: updateQuery) { response in
            print("MapDetailsTbl updateRecord Query = ",updateQuery,"Response = ",response)
            if response {
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    func deleteRecordWithLatestName( comeFromMapScreen:Bool, SessionId:Int, completion: @escaping (Bool) -> Void) {
        var deleteQuery = ""
        if comeFromMapScreen {
            deleteQuery = "DELETE FROM MapDetailsTbl  WHERE MapFileNameLatest = '' AND isNameLocalSave = 0 AND UserId = '\(MapSaveLocalResource.userName)' AND SessionId = \(SessionId)"
        }else{
            deleteQuery = "DELETE FROM MapDetailsTbl  WHERE MapFileNameLatest = '' AND isNameLocalSave = 0 AND UserId = '\(MapSaveLocalResource.userName)'"
        }
        DBManager.shared.deleteRecord(query: deleteQuery) { response in
            print("MapDetailsTbl deleteRecord Query = ",deleteQuery,"Response = ",response)
            if response {
                getDeleteParticularLatLongDetailsRecords(MapSessionId: SessionId) { response in
                    if response {
                        completion(true)
                    }else{
                        completion(false)
                    }
                }
            }else{
                completion(false)
            }
        }
    }
    
    func getRecordAllLocalTracks( isComeFromMapScreen:Bool, SessionId:Int, completion: @escaping (NSMutableArray,Bool) -> Void) {
        var getRecordStatus = ""
        if isComeFromMapScreen {
            getRecordStatus = "SELECT * FROM MapDetailsTbl WHERE UserId = '\(MapSaveLocalResource.userName)' AND isNameLocalSave = 0 AND SessionId = \(SessionId)"
        }else{
            getRecordStatus = "SELECT * FROM MapDetailsTbl WHERE UserId = '\(MapSaveLocalResource.userName)' AND isNameLocalSave = 1 "
        }
        DBManager.shared.getAllMapLocalRecords(query: getRecordStatus) { responseArray, responseStatus in
            print("MapDetailsTbl getRecordStatus Query = ",getRecordStatus,"Response = ",responseArray)
            if responseStatus {
                completion(responseArray,true)
            } else {
                completion(responseArray,false)
            }
        }
    }
    
    func getAllRecordWithParticularSessionId( SessionId:Int, completion: @escaping (NSMutableArray,Bool) -> Void) {
        let getRecordStatus  = "SELECT * FROM LatLongDetailTable WHERE UserId = '\(MapSaveLocalResource.userName)' AND MapSessionId = \(SessionId)"
        
        DBManager.shared.getAllRecordWithParticularSessionId(query: getRecordStatus) { responseArray, responseStatus in
            print("LatLongDetailTable getRecordStatus Query = ",getRecordStatus,"Response = ",responseArray)
            if responseStatus {
                completion(responseArray,true)
            }else{
                completion(responseArray,false)
            }
        }
    }
    
    func getDeleteParticularSessionIdWithRecords( MapName:String, SessionId:Int, MapFileID:Int, completion: @escaping (Bool) -> Void) {
        let deleteQuery = "DELETE FROM MapDetailsTbl  WHERE MapFileNameLatest = '\(MapName)' AND UserId = '\(MapSaveLocalResource.userName)' AND SessionId = \(SessionId) AND MapFileID = \(MapFileID)"
        DBManager.shared.deleteRecord(query: deleteQuery) { response in
            print("LatLongDetailTable getRecordStatus Query = ",deleteQuery,"Response = ",response)
            if response {
                getDeleteParticularLatLongDetailsRecords(MapSessionId: SessionId) { response1 in
                    if response1 {
                        completion(true)
                    } else{
                        completion(false)
                    }
                }
            }else{
                completion(false)
            }
        }
    }
    
    func getDeleteParticularLatLongDetailsRecords(MapSessionId:Int, completion: @escaping (Bool) -> Void) {
        let deleteQuery = "DELETE FROM LatLongDetailTable  WHERE MapSessionId = \(MapSessionId) AND UserId = '\(MapSaveLocalResource.userName)'"
        DBManager.shared.deleteRecord(query: deleteQuery) { response in
            print("LatLongDetailTable getRecordStatus Query = ",deleteQuery,"Response = ",response)
            if response {
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    func getLatestRecordForParticularUser(completion: @escaping (NSMutableArray,Bool) -> Void) {
        let getRecordStatus = "SELECT * FROM MapDetailsTbl ORDER BY Id DESC LIMIT 1"
        DBManager.shared.getAllMapLocalRecords(query: getRecordStatus) { responseArray, responseStatus in
            print("MapDetailsTbl getRecordStatus Query = ",getRecordStatus,"Response = ",responseArray)
            if responseStatus {
                completion(responseArray,true)
            } else {
                completion(responseArray,false)
            }
        }
    }
    
    func getRecordAllLocalTracksWithoutSave(completion: @escaping (Bool) -> Void) {
        let getRecordStatus = "SELECT * FROM MapDetailsTbl WHERE UserId = '\(MapSaveLocalResource.userName)' AND isNameLocalSave = 0 "
        DBManager.shared.getAllMapLocalRecords(query: getRecordStatus) { responseArray, responseStatus in
            if responseStatus {
                if responseArray.count > 0 {
                    var localMapArrayString : [MapBoxLocalTracks] = []
                    var localMapArrayDeleted =  0
                    for i in 0..<responseArray.count {
                        let mapFileInfo = responseArray[i] as? MapBoxLocalTracks
                        localMapArrayString.append(mapFileInfo!)
                    }
                    
                    for i in 0..<localMapArrayString.count {
                        let deleteQuery = "DELETE FROM MapDetailsTbl  WHERE MapFileNameLatest = '\(localMapArrayString[i].MapFileNameLatest!  ?? "")' AND UserId = '\(MapSaveLocalResource.userName)' AND SessionId = \(localMapArrayString[i].SessionId!) AND MapFileID = \(localMapArrayString[i].MapFileID!)"
                        DBManager.shared.deleteRecord(query: deleteQuery) { response in
                            if response {
                                let deleteQuery = "DELETE FROM LatLongDetailTable  WHERE MapSessionId = \(localMapArrayString[i].SessionId!) AND UserId = '\(MapSaveLocalResource.userName)'"
                                DBManager.shared.deleteRecord(query: deleteQuery) { response in
                                    localMapArrayDeleted += 1
                                }
                                if localMapArrayDeleted == localMapArrayString.count  {
                                    completion(true)
                                }
                            }else{
                                completion(true)
                            }
                        }
                    }
                }else{
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
}
