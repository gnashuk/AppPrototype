//
//  Quiz.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

class Quiz: CustomStringConvertible {
    var title: String
    var type: QuizType
    var timeLimit: TimeLimit
    var questions: [QuizQuestion] = []
    
    init(title: String, type: QuizType, timeLimit: TimeLimit, numberOfQuestions: Int) {
        self.title = title
        self.type = type
        self.timeLimit = timeLimit
        initEmptyQuestions(count: numberOfQuestions)
    }
    
    init(title: String, type: QuizType, timeLimit: TimeLimit) {
        self.title = title
        self.type = type
        self.timeLimit = timeLimit
    }
    
    private func initEmptyQuestions(count: Int) {
        for _ in 0..<count {
            questions.append(QuizQuestion())
        }
    }
    
    var description: String {
        return "<Quiz: title = \(title); type = \(type); timeLimit = \(timeLimit); question = \(questions)>"
    }
}

enum QuizType {
    case singleChoice
    case multipleChoice
    
    static func create(rawValue: String) -> QuizType? {
        switch rawValue {
        case "singleChoice":
            return .singleChoice
        case "multipleChoice":
            return .multipleChoice
        default:
            return nil
        }
    }
}

enum TimeLimit: CustomStringConvertible {
    case none
    case minutes(Int)
    
    static func create(rawValue: String) -> TimeLimit? {
        switch rawValue {
        case "none":
            return .none
        default:
            if let minutes = Int(rawValue) {
                return .minutes(minutes)
            }
            return nil
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "none"
        case .minutes(let minutes):
            return minutes.description
        }
    }
}
