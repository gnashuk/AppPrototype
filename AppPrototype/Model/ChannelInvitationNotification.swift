//
//  ChannelInvitationNotification.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/6/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChannelInvitationNotification: Notification {
    var id: String
    var date: Date
    var channelId: String
    var channelTitle: String
    var senderName: String
    
    init(id: String, date: Date, channelId: String, channelTitle: String, senderName: String) {
        self.id = id
        self.date = date
        self.channelId = channelId
        self.channelTitle = channelTitle
        self.senderName = senderName
    }
    
    static func createFrom(dataSnapshot: DataSnapshot) -> ChannelInvitationNotification? {
        if let notificationContent = dataSnapshot.value as? [String: String] {
            if let dateString = notificationContent["date"],
                let date = dateString.convertToShortDate(),
                let channelId = notificationContent["channelId"],
                let channelTitle = notificationContent["channelTitle"],
                let senderName = notificationContent["senderName"] {
                let notification = ChannelInvitationNotification(id: dataSnapshot.key, date: date, channelId: channelId, channelTitle: channelTitle, senderName: senderName)
                return notification
            }
        }
        return nil
    }
}
