//
//  ProductMapUnavailableTableViewCell.swift
//  geolocate
//
//  Created by love on 16/10/21.
//

import UIKit

class ProductMapUnavailableTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!

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

}
