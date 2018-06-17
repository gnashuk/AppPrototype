//
//  FirebaseRefs.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Firebase

class FirebaseReferences {
    static var channelsReference: DatabaseReference {
        return Database.database().reference().child("channels")
    }
    
    static var usersReference: DatabaseReference {
        return Database.database().reference().child("users")
    }
}
