//
//  QuizNotification.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/6/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation
import FirebaseDatabase

class QuizNotification: Notification {
    var id: String
    var date: Date
    var channelId: String
    var channelTitle: String
    var quizId: String
    var quizTitle: String
    var senderId: String
    
    init(id: String, date: Date, channelId: String, channelTitle: String, quizId: String, quizTitle: String, senderId: String) {
        self.id = id
        self.date = date
        self.channelId = channelId
        self.channelTitle = channelTitle
        self.quizId = quizId
        self.quizTitle = quizTitle
        self.senderId = senderId
    }
    
    static func createFrom(dataSnapshot: DataSnapshot) -> QuizNotification? {
        if let notificationContent = dataSnapshot.value as? [String: String] {
            if let dateString = notificationContent["date"],
                let date = dateString.convertToShortDate(),
                let channelId = notificationContent["channelId"],
                let channelTitle = notificationContent["channelTitle"],
                let quizId = notificationContent["quizId"],
                let quizTitle = notificationContent["quizTitle"],
                let senderId = notificationContent["senderId"] {
                let notification = QuizNotification(id: dataSnapshot.key, date: date, channelId: channelId, channelTitle: channelTitle, quizId: quizId, quizTitle: quizTitle, senderId: senderId)
                return notification
            }
        }
        return nil
    }
}
