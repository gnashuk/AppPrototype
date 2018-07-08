//
//  QuizResult.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/1/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

struct QuizResult {
    var id: String
    var senderId: String
    var senderName: String
    var date: Date
    var answers = [String: [String]]()
    
    init(id: String, senderId: String, senderName: String, date: Date, answers: [String: [String]]) {
        self.id = senderId
        self.senderId = senderId
        self.senderName = senderName
        self.date = date
        self.answers = answers
    }
}
