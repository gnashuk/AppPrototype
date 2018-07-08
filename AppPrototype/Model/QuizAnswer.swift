//
//  QuizAnswer.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

class QuizAnswer: CustomStringConvertible {
    var text: String
    var correct: Bool
    
    var description: String {
        return "<QuizAnswer: text = \(text); correct = \(correct)>"
    }
    
    init(text: String, correct: Bool) {
        self.text = text
        self.correct = correct
    }
}
