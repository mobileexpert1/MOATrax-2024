//
//  HomeViewController.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.
//

import UIKit
// swiftlint:disable identifier_name
// swiftlint:disable line_length
// swiftlint:disable empty_count
class HomeViewController: UIViewController {
    
    @IBOutlet weak var mapListTableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var logoutBtnView: UIView!
    @IBOutlet weak var myMapsBtnView: UIView!
    @IBOutlet weak var myMapsBtn: UIButton!
    @IBOutlet weak var tracksBtnView: UIView!
    @IBOutlet weak var tracksBtn: UIButton!
    
    
    var viewLogout: LogoutView?
    
    var mapListDataSource: [MapProduct] = [] {
        didSet {
            var fileState: [[FileState]] = []
            mapListDataSource.forEach { mapProduct in
                var fileStateInner: [FileState] = []
                if let mapFiles = mapProduct.mapFiles {
                    mapFiles.forEach { file in
                        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                        if let path = paths.first {
                            let fileURL = URL(fileURLWithPath: path).appendingPathComponent(file.mapFileName ?? "")
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                fileStateInner.append(.open)
                            } else {
                                fileStateInner.append(.download)
                            }
                        } else {
                            fileStateInner.append(.download)
                        }
                    }
                }
                fileState.append(fileStateInner)
            }
            mapFileCurentStatus = fileState
        }
    }
    
    var mapFileCurentStatus: [[FileState]] = []
    var temmpDataSource: [MapBoxLocalTracks] = []
    
    let pdfDownloadManager = PDFDownloadManager()
    let mapSaveResource = MapSaveLocalResource()
    let productManager = ProductManager()
    let mapManager = MapManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MapSaveLocalResource.userName = (UserDefaultsUtils.retriveStringValue(for: .firstName) ?? "") + " " + (UserDefaultsUtils.retriveStringValue(for: .lastName) ?? "")
        self.initViews()
        self.getMapList()
    }
    
    func initViews() {
        self.lblTitle.text = (UserDefaultsUtils.retriveStringValue(for: .firstName) ?? "") + " " + (UserDefaultsUtils.retriveStringValue(for: .lastName) ?? "")
        self.initLogoutView()
        self.fetchLatestRecordId()
        self.deleteUnSavedRecordFromLocalData()
        self.addLoginBtnViewGesture()
        self.addMyMapBtnViewGesture()
        self.addLocalTrackBtnViewGesture()
        self.showEmptyListIndicatorView(true)
        self.pdfDownloadManager.actionDelegate = self
        self.tracksBtnView.isHidden = true
        UserDefaultsUtils.saveUserLoggedInValue(true, keyValue: UserProfileKeys.isMyMapsTab.rawValue)
    }
    
    func showEmptyListIndicatorView(_ success: Bool) {
        self.emptyView.alpha = success ? 1.0 : 0.0
        self.mapListTableView.alpha = success ? 0.0 : 1.0
    }
    
    func addMyMapBtnViewGesture() {
        let logoutGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.didTapMyMapBtn))
        self.myMapsBtnView.addGestureRecognizer(logoutGesture)
    }
    
    func addLoginBtnViewGesture() {
        let logoutGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.acnLogOut))
        self.logoutBtnView.addGestureRecognizer(logoutGesture)
    }
    
    func addLocalTrackBtnViewGesture() {
        let logoutGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.didTapTracksBtn))
        self.tracksBtnView.addGestureRecognizer(logoutGesture)
    }
    
    func initLogoutView() {
        guard let logoutView = LogoutView.initFromNib() as? LogoutView else { return }
        
        self.viewLogout = logoutView
        self.viewLogout?.frame = self.view.bounds
        
        self.viewLogout?.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnLogoutBackView))
        viewLogout?.addGestureRecognizer(tap)
        viewLogout?.isUserInteractionEnabled = true
    }
    
    func showLogoutView(_ success: Bool) {
        if success {
            self.view.addSubview(self.viewLogout!)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.viewLogout?.logoutViewBottomConstraint.constant = success ? 0 : -270
            self.view.layoutIfNeeded()
        } completion: { _ in
            if !success {
                self.viewLogout?.removeFromSuperview()
            }
        }
    }
    
    @objc func didTapOnLogoutBackView() {
        showLogoutView(false)
    }
    
    @objc func acnLogOut() {
        showLogoutView(true)
    }
    
    @objc func didTapMyMapBtn() {
        self.getMapList()
        updateTabbarBtnImages(isMapTabSelected:true, onlyUpdateUI: false)
    }
    
    @objc func didTapTracksBtn() {
        updateTabbarBtnImages(isMapTabSelected:false,onlyUpdateUI: false)
    }
    
    func updateTabbarBtnImages(isMapTabSelected:Bool,onlyUpdateUI:Bool) {
        if isMapTabSelected {
            updateImage(btnView: myMapsBtn, imageName: MapDetailScreenConstant.MapSelectedImgNameStr)
            updateImage(btnView: tracksBtn, imageName:  MapDetailScreenConstant.LocationUnSelectedImgNameStr)
            UserDefaultsUtils.saveUserLoggedInValue(true, keyValue: UserProfileKeys.isMyMapsTab.rawValue)
        } else {
            updateImage(btnView: myMapsBtn, imageName:  MapDetailScreenConstant.MapUnSelectedImgNameStr)
            updateImage(btnView: tracksBtn, imageName:  MapDetailScreenConstant.LocationSelectedImgNameStr)
            UserDefaultsUtils.saveUserLoggedInValue(false, keyValue: UserProfileKeys.isMyMapsTab.rawValue)
            fetchAllLocalTracks { responeCount in }
        }
        self.mapListTableView.reloadData()
    }
    
    func updateImage(btnView:UIButton,imageName:String) {
        btnView.setImage(UIImage(named: imageName), for: .normal)
    }
    
    
    func fetchAllLocalTracks(completion: @escaping (Int) -> Void) {
        mapSaveResource.getRecordAllLocalTracks(isComeFromMapScreen:false,SessionId:0) { [self] responseArray, responsseStatus in
            temmpDataSource.removeAll()
            var localMapArrayString : [MapBoxLocalTracks] = []
            for i in 0..<responseArray.count {
                let mapFileInfo = responseArray[i] as? MapBoxLocalTracks
                localMapArrayString.append(mapFileInfo!)
            }
            
            if self.mapListDataSource.count > 0 {
                for t in 0..<localMapArrayString.count {
                    for i in 0..<mapListDataSource.count {
                        if self.mapListDataSource[i].mapFiles?.count ?? 0 > 0 {
                            for j in 0..<mapListDataSource[i].mapFiles!.count  {
                                if self.mapListDataSource[i].mapFiles!.indices.contains(j) {
                                    if localMapArrayString[t].MapFileID == mapListDataSource[i].mapFiles![j].mapFileID {
                                        if let _ = mapListDataSource[i].mapFiles!.firstIndex(where: { $0.mapFileID == localMapArrayString[t].MapFileID }) {
                                            //print("is contain item = ",temmpDataSource.contains(localMapArrayString[t]),"\ntemDataSource = ",temmpDataSource,"\ntemDataSource = ",localMapArrayString[t])
                                            if !temmpDataSource.contains(localMapArrayString[t]) {
                                                temmpDataSource.append(localMapArrayString[t])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            print("Total Count in local Track = ",temmpDataSource.count)
            if  temmpDataSource.count > 0 {
                tracksBtnView.isHidden = false
                self.temmpDataSource = self.temmpDataSource.sorted(by: { $0.id! > $1.id!})
            }
            completion(temmpDataSource.count)
            self.mapListTableView.reloadData()
        }
    }
    
    func fetchLatestRecordId(){
        print(UserDefaultsUtils.retriveSessionIdForLocalDatabase(keyValue: UserProfileKeys.isSessionId.rawValue))
        if UserDefaultsUtils.retriveSessionIdForLocalDatabase(keyValue: UserProfileKeys.isSessionId.rawValue) == 0 {
            mapSaveResource.getLatestRecordForParticularUser { responseArray, responseStatus in
                if responseArray.count > 0 {
                    let mapFileInfo = responseArray[0] as? MapBoxLocalTracks
                    UserDefaultsUtils.saveSessionIdForLocalDatabase(mapFileInfo!.id!+1, keyValue: UserProfileKeys.isSessionId.rawValue)
                    print(UserDefaultsUtils.retriveSessionIdForLocalDatabase(keyValue: UserProfileKeys.isSessionId.rawValue))
                }
            }
        }
    }
    
    func deleteUnSavedRecordFromLocalData(){
        self.mapSaveResource.getRecordAllLocalTracksWithoutSave(completion: { response in
            print("response = ",response)
        })
    }
}

// MARK: - Get Map List

extension HomeViewController {
    func getMapList() {
        
        if ConnectionManager.shared.hasConnectivity() {
            
            let homeResource = HomeResource()
            
            Loader.shared.showSpinner()
            
            homeResource.getMapList(completion: { response, error in
                if let error = error {
                    debugPrint(error)
                    Loader.shared.hideSpinner()
                    ToastUtils.shared.showToast(with: error)
                    
                } else {
                    // login result
                    if let result = response {
                        if result.statusCode == .success {
                            Loader.shared.hideSpinner()
                            
                            // cancel previous tasks
                            
                            self.pdfDownloadManager.downloadableDataTasks.forEach { task in
                                task.cancel()
                            }
                            
                            self.pdfDownloadManager.downloadableItems.forEach { item in
                                item.workItem.cancel()
                            }
                            
                            self.pdfDownloadManager.downloadableItems = []
                            self.pdfDownloadManager.downloadableDataTasks = []
                            
                            if let productResult = result.model {
                                self.productManager.insertUpdateProduct(with: productResult)
                                self.mapListDataSource = self.productManager.fetchProduct() ?? []
                                self.fetchAllLocalTracks { responeCount in }
                                self.mapListTableView.reloadData()
                                self.showEmptyListIndicatorView(productResult.isEmpty)
                            }
                        } else {
                            debugPrint("errror")
                            Loader.shared.hideSpinner()
                            ToastUtils.shared.showToast(with: result.message)
                        }
                    } else {
                        Loader.shared.hideSpinner()
                        debugPrint(HUErrorMessage.emptyResponse.rawValue)
                    }
                }
            })
        } else {
            self.mapListDataSource = self.productManager.fetchProduct() ?? []
            self.mapListTableView.reloadData()
            self.fetchAllLocalTracks{ responeCount in }
            self.showEmptyListIndicatorView(self.mapListDataSource.isEmpty)
        }
    }
}

// MARK: - Download and cancel file

extension HomeViewController: PDFDownloadActions {
    
    func downloadingCompleted(with file: String?, request: DownloadRequest) {
        guard let fileURL = file else {
            downloadingFailed(with: "not received data from api", request: request)
            return
        }
        
        var updatedMapItem = request.mapItem
        updatedMapItem.mapFileLocalURL = fileURL
        
        let updateMapResult = mapManager.updateMap(map: updatedMapItem)
        if updateMapResult {
            mapListDataSource[request.mapIndexPath.section].mapFiles?[request.mapIndexPath.row] = updatedMapItem
            self.mapFileCurentStatus[request.mapIndexPath.section][request.mapIndexPath.row] = .open
            self.mapListTableView.reloadRows(at: [request.mapIndexPath], with: .automatic)
        }
    }
    
    func downloadingFailed(with error: String, request: DownloadRequest) {
        ToastUtils.shared.showToast(with: error)
        self.mapFileCurentStatus[request.mapIndexPath.section][request.mapIndexPath.row] = .download
        self.mapListTableView.reloadRows(at: [request.mapIndexPath], with: .automatic)
    }
}

// MARK: - map list view Delegate & Data Source

extension HomeViewController: UITableViewDelegate, UITableViewDataSource,UpdateMainViewControllerLocalTracksValuesDelegate {
    func checkNameExistOrNot(pdfName: String) -> Bool {
        var nameExistAlready = false
        if let _ = temmpDataSource.firstIndex(where: { $0.MapFileNameLatest == pdfName }) {
            nameExistAlready = true
        }
        return nameExistAlready
    }
    
    func updateMainViewControllerLocalResponse(isBack: Bool) {
        if isBack {
            fetchAllLocalTracks { responeCount in }
            tracksBtnView.isHidden = false
            updateTabbarBtnImages(isMapTabSelected:false, onlyUpdateUI: false)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if  !UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
            return 1
        }
        return mapListDataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  !UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
            return temmpDataSource.count
        }
        if let mapCount = mapListDataSource[section].mapFiles?.count {
            return mapCount == 0 ? 1 : mapCount
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if  !UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
            if let mapItemCell = tableView.dequeueReusableCell(withIdentifier: MapItemTableViewCell.className) as? MapItemTableViewCell {
                mapItemCell.selectionStyle = .none
                let mapfileData = MapFile.init(mapFile: temmpDataSource[indexPath.row].MapFile!, mapFileID: temmpDataSource[indexPath.row].MapFileID!, mapFileName: temmpDataSource[indexPath.row].MapFileNameLatest!, mapInfoJSON: temmpDataSource[indexPath.row].MapInfoJSON, mapFileLocalURL: temmpDataSource[indexPath.row].MapFileLocalURL)
                mapItemCell.initViews(with: mapfileData)
                mapItemCell.actionDelegates = self
                mapItemCell.setFileState(.open)
                mapItemCell.currentIndex = indexPath
                return mapItemCell
            }
        }else{
            if let mapCount = mapListDataSource[indexPath.section].mapFiles?.count {
                if mapCount == 0 {
                    if let mapUnavailableCell = tableView.dequeueReusableCell(withIdentifier: ProductMapUnavailableTableViewCell.className) as? ProductMapUnavailableTableViewCell {
                        mapUnavailableCell.selectionStyle = .none
                        return mapUnavailableCell
                    }
                }
            }
            if let mapItemCell = tableView.dequeueReusableCell(withIdentifier: MapItemTableViewCell.className) as? MapItemTableViewCell {
                mapItemCell.selectionStyle = .none
                mapItemCell.initViews(with: mapListDataSource[indexPath.section].mapFiles?[indexPath.row])
                mapItemCell.actionDelegates = self
                mapItemCell.setFileState(mapFileCurentStatus[indexPath.section][indexPath.row])
                mapItemCell.currentIndex = indexPath
                return mapItemCell
            }
        }
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableCell(withIdentifier: MapHeaderTableViewCell.className) as? MapHeaderTableViewCell {
            if  UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
                headerView.headerTitleLbl.text = mapListDataSource[section].displayName
            }else{
                headerView.headerTitleLbl.text = MapDetailScreenConstant.ListOfSavedTracks
            }
            headerView.contentView.backgroundColor = UIColor.init(named: "#F8FDFF")
            return headerView.contentView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if  !UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if  !UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
            if editingStyle == .delete {
                mapSaveResource.getDeleteParticularSessionIdWithRecords(MapName: temmpDataSource[indexPath.row].MapFileNameLatest!!, SessionId:temmpDataSource[indexPath.row].SessionId! , MapFileID: temmpDataSource[indexPath.row].MapFileID!) { response in
                    self.fetchAllLocalTracks { responeCount in
                        if responeCount == 0 {
                            self.tracksBtnView.isHidden = true
                            self.updateTabbarBtnImages(isMapTabSelected: true, onlyUpdateUI: true)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Map Item Actions

extension HomeViewController: MapItemActions {
    func didTapDownloadFile(at index: IndexPath?) {
        // download file
        guard let index = index, let mapItem = mapListDataSource[index.section].mapFiles?[index.row] else {
            return
        }
        
        let request = DownloadRequest.init(mapItem: mapItem, mapIndexPath: index)
        pdfDownloadManager.addFileToDownloadWith(request: request)
        pdfDownloadManager.startDownloadingFile(with: request)
        
        self.mapFileCurentStatus[index.section][index.row] = .processing
        self.mapListTableView.reloadRows(at: [index], with: .automatic)
        
    }
    
    func didTapOpenFile(at index: IndexPath?) {
        //  view file
        guard let index = index else {
            return
        }
        if let mapViewController = HomeRoute.mapPreviewViewController.controller as? MapPreviewViewController {
            if  UserDefaultsUtils.retriveUserLoggedInValue(keyValue: UserProfileKeys.isMyMapsTab.rawValue) {
                mapViewController.mapItem = self.mapListDataSource[index.section].mapFiles?[index.row]
                mapViewController.isComeFromMapScreen = false
            }else{
                let mapfileData = MapFile.init(mapFile: temmpDataSource[index.row].MapFile!, mapFileID: temmpDataSource[index.row].MapFileID!, mapFileName: temmpDataSource[index.row].MapFileNameDefault!, mapInfoJSON: temmpDataSource[index.row].MapInfoJSON, mapFileLocalURL: temmpDataSource[index.row].MapFileLocalURL,sessionIdLocal:temmpDataSource[index.row].SessionId)
                mapViewController.mapItem = mapfileData
                mapViewController.isComeFromMapScreen = true
            }
            mapViewController.delegate = self
            self.navigationController?.pushViewController(mapViewController, animated: true)
        }
    }
}

// MARK: - Logout Popup Actions

extension HomeViewController: logOutViewDelegate {
    func delegateLogOutAcn() {
        showLogoutView(false)
        
        if productManager.deleteAllProducts() {
            if mapManager.deleteAllMap() {
                UserDefaultsUtils.logoutUser()
                self.navigationController?.viewControllers = [self]
                if let loginVC = Storyboards.authentication.instance.instantiateViewController(withIdentifier: AuthenticationRoute.logInViewController.rawValue) as? LoginViewController {
                    self.navigationController?.push(viewController: loginVC, transitionType: .fade, duration: 0.3)
                }
            }
        }
    }
    
    func delegateCancelAcn() {
        showLogoutView(false)
    }
}
