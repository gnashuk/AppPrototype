//
//  FirebaseRefs.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class FirebaseReferences {
    static let storageUrl = "gs://appprototype-9cf29.appspot.com"
    
    static var channelsReference: DatabaseReference {
        return Database.database().reference().child("channels")
    }
    
    static var usersReference: DatabaseReference {
        return Database.database().reference().child("users")
    }
    
    static var storageReference: StorageReference {
        return Storage.storage().reference(forURL: storageUrl)
    }
}
