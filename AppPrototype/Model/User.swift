//
//  User.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

struct User: Hashable, CustomStringConvertible {
    var hashValue: Int {
        return userId.hashValue
    }
    
    var userId: String
    var userName: String
    var profileImageURL: String?
    
    var description: String {
        return "userId: \(userId)\nuserName: \(userName)\nprofileImageURL: \(String(describing: profileImageURL))"
    }
    
    init(userId: String, userName: String, profileImageURL: String? = nil) {
        self.userId = userId
        self.userName = userName
        self.profileImageURL = profileImageURL
    }
}
