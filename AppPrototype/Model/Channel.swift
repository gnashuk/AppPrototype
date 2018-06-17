//
//  Channel.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

struct Channel {
    var id: String
    var title: String
    var ownerId: String
    var description: String
    
    init(id: String, title: String, ownerId: String, description: String) {
        self.id = id
        self.title = title
        self.ownerId = ownerId
        self.description = description
    }
}
