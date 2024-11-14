//
//  MapItemTableViewCell.swift
//  geolocate
//
//  Created by love on 29/09/21.
//

import UIKit

protocol MapItemActions: AnyObject {
    func didTapDownloadFile(at index: IndexPath?)
    func didTapOpenFile(at index: IndexPath?)
}

class MapItemTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var mapTitleLbl: UILabel!
  
    @IBOutlet weak var downloadFileBtn: CustomUIButton!
    @IBOutlet weak var openFileBtn: CustomUIButton!
    @IBOutlet weak var processingView: CustomUIView!
    
    weak var actionDelegates: MapItemActions?
    var mapFileItem: MapFile?
    var currentIndex: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowColor = UIColor(red: 132.0/255.0, green: 145.0/255.0, blue: 139.0/255.0, alpha: 1.0)
        containerView.layer.cornerRadius = 8.0
        containerView.addShadow(offset: .init(width: 0, height: 3), color: shadowColor, radius: 3, opacity: 0.10)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initViews(with item: MapFile?) {
        mapFileItem = item
        mapTitleLbl.text = item?.mapFileName
    }
    
    func setFileState(_ state: FileState) {
        if state == .download {
            downloadFileBtn.alpha = 1.0
            openFileBtn.alpha = 0.0
            processingView.alpha = 0.0
        } else if state == .open {
            downloadFileBtn.alpha = 0.0
            openFileBtn.alpha = 1.0
            processingView.alpha = 0.0
        } else {
            downloadFileBtn.alpha = 0.0
            openFileBtn.alpha = 0.0
            processingView.alpha = 1.0
        }
    }

    @IBAction func downloadFileAction(_ sender: UIButton) {
        actionDelegates?.didTapDownloadFile(at: self.currentIndex)
    }
  
    @IBAction func openFileAction(_ sender: UIButton) {
        actionDelegates?.didTapOpenFile(at: self.currentIndex)
    }
}

enum FileState {
    case download
    case processing
    case open
}
