//
//  Quiz.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Quiz: CustomStringConvertible {
    var id: String?
    var title: String
    var type: QuizType
    var timeLimit: TimeLimit
    var questions: [QuizQuestion] = []
    var results: [QuizResult] = []
    
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
    
    func resetAnswers() {
        questions.forEach { (question) in
            question.answers.forEach({ $0.correct = false })
        }
    }
    
    static func createFrom(dataSnapshot: DataSnapshot) -> Quiz? {
        if let quizContent = parseQuizContent(dataSnapshot: dataSnapshot) {
            if let title = quizContent["title"] as? String, let typeString = quizContent["type"] as? String, let timeLimitString = quizContent["timeLimit"] as? String {
                if let questions = quizContent["questions"] as? [String: Any], let type = QuizType.create(rawValue: typeString), let timeLimit = TimeLimit.create(rawValue: timeLimitString) {
                    let quiz = Quiz(title: title, type: type, timeLimit: timeLimit)
                    quiz.id = dataSnapshot.key
                    for (_, value) in questions {
                        if let questionContent = value as? [String: Any] , let answers = questionContent["answers"] as? [String: Any], let questionTitle = questionContent["title"] as? String {
                            let question = QuizQuestion()
                            question.title = questionTitle
                            for (_, value) in answers {
                                if let answerContent = value as? [String: Any], let text = answerContent["text"] as? String, let correct = answerContent["correct"] as? Bool {
                                    let answer = QuizAnswer(text: text, correct: correct)
                                    question.answers.append(answer)
                                }
                            }
                            quiz.questions.append(question)
                        }
                    }
                    return quiz
                }
            }
        }
        return nil
    }
    
    private static func parseQuizContent(dataSnapshot: DataSnapshot) -> [String: Any]? {
        if let quizContent = dataSnapshot.value as? [String: Any] {
            return quizContent
        } else if let map = dataSnapshot.value as? [String: Any], let quizContent = map.first?.value as? [String: Any] {
            return quizContent
        }
        return nil
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
            return TimeLimit.none
        default:
            if let minutes = Int(rawValue) {
                return TimeLimit.minutes(minutes)
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
