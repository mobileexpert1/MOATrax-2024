//
//  PDFDownloadManager.swift
//  geolocate
//
//  Created by love on 12/10/21.
//

import Foundation

protocol PDFDownloadActions: AnyObject {
    func downloadingCompleted(with file: String?, request: DownloadRequest)
    func downloadingFailed(with error: String, request: DownloadRequest)
}

class PDFDownloadManager {
    
    var downloadableItems: [PDFDownloadRequest] = []
    var downloadableDataTasks: [URLSessionDataTask] = []
    
    weak var actionDelegate: PDFDownloadActions?
    let downloadQueue = DispatchQueue.init(label: "downloadPDFQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    func addFileToDownloadWith(request: DownloadRequest) {
        let dowloadFileWorkItem = DispatchWorkItem {
            self.createDownloadRequest(with: request)
        }
        
        var downloadRequest = PDFDownloadRequest.init(workItem: dowloadFileWorkItem, mapItem: request.mapItem, mapIndexPath: request.mapIndexPath)
        downloadRequest.workItem = dowloadFileWorkItem
        downloadableItems.append(downloadRequest)
    }
    
    func startDownloadingFile(with request: DownloadRequest) {
        if let indexInDownloadItems = downloadableItems.firstIndex(where: {$0.mapItem.mapFileID == request.mapItem.mapFileID}) {
            downloadQueue.async(execute: self.downloadableItems[indexInDownloadItems].workItem)
        } else {
            actionDelegate?.downloadingFailed(with: "error downloading file Cannot file download request record", request: request)
        }
    }
    
    private func createDownloadRequest(with item: DownloadRequest) {
        guard let urlString = item.mapItem.mapFile.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let url = URL(string: urlString) else { return }
        
        let urlRequest = URLRequest(url: url)
        
        downloadFile(with: urlRequest) { fileData, error in
            if let error = error {
                self.actionDelegate?.downloadingFailed(with: error, request: item)
            } else {
                let savedFileURL = PDCache.sharedInstance.saveData(obj: fileData!, fileName: item.mapItem.mapFileName ?? "")
                
                if var urlPath = savedFileURL?.path {
                    urlPath = urlPath.replacingOccurrences(of: "%20", with: " ")
                    urlPath = urlPath.replacingOccurrences(of: "file://", with: "")
                    self.actionDelegate?.downloadingCompleted(with: urlPath, request: item)
                }
            }
        }
    }
    
    private func downloadFile(with request: URLRequest, completion: @escaping (Data?, String?) -> Void) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 100.0
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    completion(nil, error?.localizedDescription)
                    return
                }
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                guard let fileData = data else {
                    completion(nil, "file data not received")
                    return
                }
                completion(fileData, nil)
            }
        }
        task.resume()
        downloadableDataTasks.append(task)
    }
}

struct PDFDownloadRequest {
    var workItem: DispatchWorkItem
    var mapItem: MapFile
    var mapIndexPath: IndexPath
}

struct DownloadRequest {
    var mapItem: MapFile
    var mapIndexPath: IndexPath
}

class PDCache: NSObject {
    
    static let sharedInstance = PDCache()
    
    func saveData(obj: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil}
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            try obj.write(to: url, options: .atomic)
            return url
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func getData(fileName: String) -> URL? {
        let fileManager = FileManager.default
        let filename = getDocumentsDirectory().appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: filename.path) {
            return URL(fileURLWithPath: filename.path)
        }
        return nil
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
