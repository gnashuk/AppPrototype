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
    var userIds: [String]?
    var isPrivate: Bool = false
    
    init(id: String, title: String, ownerId: String, description: String, userIds: [String]? = nil, isPrivate: Bool = false) {
        self.id = id
        self.title = title
        self.ownerId = ownerId
        self.description = description
        self.userIds = userIds
        self.isPrivate = isPrivate
    }
}
