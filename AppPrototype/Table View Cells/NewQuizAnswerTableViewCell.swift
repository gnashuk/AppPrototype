//
//  NewQuizAnswerTableViewCell.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

protocol ExpandableCellDelegate {
    func updateCell(at indexPath: IndexPath, height: CGFloat?)
}

protocol AnswerCellDelegate {
    func presentAlert(title: String, message: String)
}

class NewQuizAnswerTableViewCell: UITableViewCell, UITextViewDelegate {

    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var answerTextArea: UITextView! {
        didSet {
            answerTextArea.delegate = self
            answerTextArea.text = LocalizedStrings.TextViewText.AnswerText
            answerTextArea.textColor = UIColor.lightGray
            answerTextArea.layer.borderColor = UIColor.gray.cgColor
            answerTextArea.layer.borderWidth = 0.25
            answerTextArea.layer.cornerRadius = 5.0
        }
    }
    
    var answerText: String {
        get {
            return answerTextArea.text
        }
        set {
            answerTextArea.text = newValue
            answerTextArea.textColor = UIColor.black
            answerTextArea.layer.borderWidth = 0.25
            answerTextArea.layer.cornerRadius = 5.0
            addButton.isEnabled = true
        }
    }
    
    var expandableCellDelegate: ExpandableCellDelegate?
    var answerCellDelegate: AnswerCellDelegate?
    
    var indexPath: IndexPath?
    var quiz: Quiz?
    var tableView: UITableView?
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if let text = answerTextArea.text, !text.isEmpty, indexPath != nil {
            if isUnique(answer: text, indexPath: indexPath!) {
                updateCell(height: nil)
                quiz?.questions[indexPath!.section].answers.append(QuizAnswer(text: text, correct: false))
                answerTextArea.text = nil
                answerTextArea.tag = 1
                tableView?.reloadData()
            } else {
                answerCellDelegate?.presentAlert(title: LocalizedStrings.AlertTitles.DuplicateAnswer, message: LocalizedStrings.AlertMessages.DuplicateAnswer)
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let text = answerTextArea.text {
            addButton.isEnabled = !text.isEmpty
            return
        }
        addButton.isEnabled = false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if answerTextArea.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        answerTextArea.tag = 0
        updateCell(height: 96)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if answerTextArea.text.isEmpty {
            textView.text = LocalizedStrings.TextViewText.AnswerText
            textView.textColor = UIColor.lightGray
        }
        if answerTextArea.tag == 0 {
            updateCell(height: nil)
        }
        
    }
    
    private func updateCell(height: CGFloat?) {
        if indexPath != nil, answerTextArea.text != nil {
            expandableCellDelegate?.updateCell(at: indexPath!, height: height)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }
    
    private func isUnique(answer: String, indexPath: IndexPath) -> Bool {
        if let question = quiz?.questions[indexPath.section] {
            return question.answers.filter({ $0.text.lowercased() == answer.lowercased() }).isEmpty
        }
        return false
    }
}
