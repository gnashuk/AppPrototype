//
//  QuizQuestion.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

class QuizQuestion: CustomStringConvertible {
    var collapsed = false
    
    var title: String = ""
    var answers: [QuizAnswer] = []
    
    var description: String {
        return "<QuizQuestion: title = \(title); answers = \(answers); collapsed = \(collapsed)>"
    }
}


