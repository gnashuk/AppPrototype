//
//  Channel.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import FirebaseDatabase

class Channel {
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
    
    static func createForm(dataSnapshot: DataSnapshot) -> Channel? {
        if let channelData = dataSnapshot.value as? [String: Any] {
            if let title = channelData["title"] as? String, let ownerId = channelData["ownerId"] as? String, let description = channelData["description"] as? String, let isPrivate = channelData["isPrivate"] as? Bool, !title.isEmpty {
                return Channel(id: dataSnapshot.key, title: title, ownerId: ownerId, description: description, isPrivate: isPrivate)
            }
        }
        return nil
    }
}
