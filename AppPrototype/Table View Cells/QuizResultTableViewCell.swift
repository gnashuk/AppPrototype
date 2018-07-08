//
//  QuizResultTableViewCell.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/1/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class QuizResultTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
