//
//  UserImageCollectionViewCell.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/1/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class UserImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = 20
            profileImageView.layer.masksToBounds = true
        }
    }
}
