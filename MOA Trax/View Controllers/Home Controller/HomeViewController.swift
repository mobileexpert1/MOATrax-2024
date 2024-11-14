//
//  HomeViewController.swift
//  geolocate
//
//  Created by Appentus Technologies on 22/09/21.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var mapListTableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var logoutBtnView: UIView!
    @IBOutlet weak var myMapsBtnView: UIView!
    @IBOutlet weak var tracksBtnView: UIView!
    
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
    
    let productManager = ProductManager()
    let mapManager = MapManager()
    
    let pdfDownloadManager = PDFDownloadManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.getMapList()
    }
    
    func initViews() {
        self.lblTitle.text = (UserDefaultsUtils.retriveStringValue(for: .firstName) ?? "") + " " + (UserDefaultsUtils.retriveStringValue(for: .lastName) ?? "")
        self.initLogoutView()
        self.addLoginBtnViewGesture()
        self.addMyMapBtnViewGesture()
        self.addTracksBtnViewGesture()
        self.showEmptyListIndicatorView(true)
        pdfDownloadManager.actionDelegate = self
    }
    
    func showEmptyListIndicatorView(_ success: Bool) {
        self.emptyView.alpha = success ? 1.0 : 0.0
        self.mapListTableView.alpha = success ? 0.0 : 1.0
    }
    
    
    func addTracksBtnViewGesture() {
        let trackBtnGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.didTapTracksBtn))
        self.tracksBtnView.addGestureRecognizer(trackBtnGesture)
    }
    
    func addMyMapBtnViewGesture() {
        let logoutGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.didTapMyMapBtn))
        self.myMapsBtnView.addGestureRecognizer(logoutGesture)
    }
    
    func addLoginBtnViewGesture() {
        let logoutGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.acnLogOut))
        self.logoutBtnView.addGestureRecognizer(logoutGesture)
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
    }
    
    @objc func didTapTracksBtn() {
        print("Testing Button track Pressed")
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

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return mapListDataSource.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mapCount = mapListDataSource[section].mapFiles?.count {
            return mapCount == 0 ? 1 : mapCount
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableCell(withIdentifier: MapHeaderTableViewCell.className) as? MapHeaderTableViewCell {
            headerView.headerTitleLbl.text = mapListDataSource[section].displayName
            headerView.contentView.backgroundColor = UIColor.init(named: "#F8FDFF")
            return headerView.contentView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
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
            mapViewController.mapItem = self.mapListDataSource[index.section].mapFiles?[index.row]
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
