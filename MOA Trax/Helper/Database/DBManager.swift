//
//  File.swift
//  MOA Trax
//
//  Created by apple on 29/03/22.
//
import UIKit
import SQLite3

let database = "MoaTrax"
class DBManager: NSObject {
    static let shared  = DBManager()
    
    var db: OpaquePointer?
    
    class func createEditableCopyOfDatabaseIfNeeded() {
        let success : Bool!
        let fileManager =  FileManager.default
        let _ : Error
        let paths =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory =  paths[0] as NSString
        let path =   documentDirectory.appendingPathComponent(database) as NSString
        success =  fileManager.fileExists(atPath: path as String)
        if success {
            //print("ALready exists Path = ",path)
            return;
        }
        let baseDBPath =  Bundle.main.resourcePath! as NSString
        let completeDBPath =  baseDBPath.appendingPathComponent(database)
        //print("CompleteDBPath = ",completeDBPath)
        do {
            try fileManager.copyItem(atPath: completeDBPath, toPath: path as String)
        }
        catch  {
            print("Ooops! Something went wrong: ")
        }
    }
    
    
    func openConnection()  {
        let paths =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory =  paths[0] as NSString
        let path = documentDirectory.appendingPathComponent(database) as NSString
        //print("OpenConnection path = ",path)
        if sqlite3_open(path.utf8String, &db) == SQLITE_OK {
            //print("Database Successfully Opened")
        }else {
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
        }
    }
    
    func closeConnection()  {
        sqlite3_close(db)
    }
    
    func insertRecord(query: String,completion: @escaping (Bool) -> Void) {
        self.openConnection()
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &insertStatement, nil) == SQLITE_OK {
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                //print("Successfully inserted row.")
                completion(true)
            } else {
                ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
                completion(false)
            }
        } else {
            completion(false)
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_finalize(insertStatement)
    }
    
    
    func deleteRecord(query: String,completion: @escaping (Bool) -> Void) {
        openConnection()
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK {
            print("Delete Record Status = ",sqlite3_step(selectStatement))
            completion(true)
            sqlite3_finalize(selectStatement)
            closeConnection()
        } else {
            completion(false)
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
        }
    }
    
    func updateRecord(query: String,completion: @escaping (Bool) -> Void) {
        openConnection()
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK {
            _ = sqlite3_step(selectStatement)
            sqlite3_finalize(selectStatement)
            completion(true)
            closeConnection()
        } else {
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
            completion(false)
        }
    }
    
    func getAllMapLocalRecords(query: String,completion: @escaping (NSMutableArray,Bool) -> Void) {
        let list  = NSMutableArray()
        openConnection()
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var dict = [String: Any] ()
                let id = Int(sqlite3_column_int(selectStatement, 0))
                let userId = String(cString: sqlite3_column_text(selectStatement, 1))
                let sessionId = Int(sqlite3_column_int(selectStatement, 2))
                let mapFile = String(cString: sqlite3_column_text(selectStatement, 3))
                let mapFileID = Int(sqlite3_column_int(selectStatement, 4))
                let mapFileNameDefault = String(cString: sqlite3_column_text(selectStatement, 5))
                let mapFileNameLatest = String(cString: sqlite3_column_text(selectStatement, 6))
                let nameLocalSave = Double(sqlite3_column_int(selectStatement, 7))
                let mapInfoJSON = String(cString: sqlite3_column_text(selectStatement, 8))
                dict.updateValue(id, forKey: "Id")
                dict.updateValue(userId, forKey: "UserId")
                dict.updateValue(sessionId, forKey: "SessionId")
                dict.updateValue(mapFile, forKey: "MapFile")
                dict.updateValue(mapFileID, forKey: "MapFileID")
                dict.updateValue(mapFileNameDefault, forKey: "MapFileNameDefault")
                dict.updateValue(mapFileNameLatest, forKey: "MapFileNameLatest")
                dict.updateValue(nameLocalSave, forKey: "isNameLocalSave")
                dict.updateValue(mapInfoJSON, forKey: "MapInfoJSON")
                list.add(MapBoxLocalTracks.mapBoxLocalData(info: dict as AnyObject))
            }
            sqlite3_finalize(selectStatement)
            completion(list,true)
            closeConnection()
        } else {
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
            completion(list,false)
        }
    }
    
    
    func getAllRecordWithParticularSessionId(query: String,completion: @escaping (NSMutableArray,Bool) -> Void) {
        let list  = NSMutableArray()
        openConnection()
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var dict = [String: Any] ()
                let id = String(cString: sqlite3_column_text(selectStatement, 0))
                let userId = String(cString: sqlite3_column_text(selectStatement, 1))
                let mapSessionId = String(cString: sqlite3_column_text(selectStatement, 2))
                let latitude = Double(sqlite3_column_double(selectStatement, 3))
                let longitude = Double(sqlite3_column_double(selectStatement, 4))
                dict.updateValue(id, forKey: "Id")
                dict.updateValue(userId, forKey: "UserId")
                dict.updateValue(mapSessionId, forKey: "MapSessionId")
                dict.updateValue(latitude, forKey: "Latitude")
                dict.updateValue(longitude, forKey: "Longitude")
                list.add(LatLongDetailTable.listOfMapLatLongDetails(info: dict as AnyObject))
            }
            sqlite3_finalize(selectStatement)
            completion(list,true)
            closeConnection()
        } else {
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
            completion(list,false)
        }
    }
    
    func checkCurrentSessionIdIsAvalible(query: String,completion: @escaping (NSMutableArray,Bool) -> Void) {
        let list  = NSMutableArray()
        openConnection()
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var dict = [String: Any] ()
                let id = String(cString: sqlite3_column_text(selectStatement, 0))
                let userId = String(cString: sqlite3_column_text(selectStatement, 1))
                let sessionId = String(cString: sqlite3_column_text(selectStatement, 2))
                let mapFile = String(cString: sqlite3_column_text(selectStatement, 3))
                let mapFileID = Int(sqlite3_column_int(selectStatement, 4))
                let mapFileNameDefault = String(cString: sqlite3_column_text(selectStatement, 5))
                let mapFileNameLatest = String(cString: sqlite3_column_text(selectStatement, 6))
                let nameLocalSave = Double(sqlite3_column_int(selectStatement, 7))
                let mapInfoJSON = String(cString: sqlite3_column_text(selectStatement, 8))
                dict.updateValue(id, forKey: "Id")
                dict.updateValue(userId, forKey: "UserId")
                dict.updateValue(sessionId, forKey: "SessionId")
                dict.updateValue(mapFile, forKey: "MapFile")
                dict.updateValue(mapFileID, forKey: "MapFileID")
                dict.updateValue(mapFileNameDefault, forKey: "MapFileNameDefault")
                dict.updateValue(mapFileNameLatest, forKey: "MapFileNameLatest")
                dict.updateValue(nameLocalSave, forKey: "isNameLocalSave")
                dict.updateValue(mapInfoJSON, forKey: "MapInfoJSON")
                list.add(MapBoxLocalTracks.mapBoxLocalData(info: dict as AnyObject))
            }
            sqlite3_finalize(selectStatement)
            completion(list,true)
            closeConnection()
        } else {
            ToastUtils.shared.showToast(with: String(cString: sqlite3_errmsg(db)))
            completion(list,false)
        }
    }
}
