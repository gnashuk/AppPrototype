//
//  Quiz.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

struct Quiz {
    var title: String
    var type: QuizType
}

enum QuizType {
    case singleChoice
    case multipleChoice
}
