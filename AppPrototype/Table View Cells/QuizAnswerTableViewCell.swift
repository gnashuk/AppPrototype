//
//  QuizAnswerTableViewCell.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/27/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import BEMCheckBox

class QuizAnswerTableViewCell: UITableViewCell, BEMCheckBoxDelegate {

    @IBOutlet weak var answerBackgroundView: UIView!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var checkBox: BEMCheckBox! {
        didSet {
            checkBox.delegate = self
            checkBox.onAnimationType = .bounce
            checkBox.offAnimationType = .bounce
        }
    }
    
    var quiz: Quiz?
    var indexPath: IndexPath?
    
    func didTap(_ checkBox: BEMCheckBox) {
        updateModel(checkBox.on)
    }
    
    func didSelectCell() {
        checkBox.setOn(!checkBox.on, animated: true)
        updateModel(checkBox.on)
    }
    
    private func updateModel(_ checkBoxState: Bool) {
        if let quiz = quiz,let section = indexPath?.section, let row = indexPath?.row {
            if quiz.type == .singleChoice {
                for answer in quiz.questions[section].answers {
                    answer.correct = false
                }
            }
            quiz.questions[section].answers[row - 1].correct = checkBoxState
        }
    }

}
