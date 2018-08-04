//
//  QuestionTitleTableViewCell.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class QuestionTitleTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var questionTextArea: UITextView! {
        didSet {
            questionTextArea.delegate = self
            questionTextArea.text = LocalizedStrings.TextViewText.Title
            questionTextArea.textColor = UIColor.lightGray
            questionTextArea.layer.borderColor = UIColor.gray.cgColor
            questionTextArea.layer.borderWidth = 0.25
            questionTextArea.layer.cornerRadius = 5.0
        }
    }
    
    var expandableCellDelegate: ExpandableCellDelegate?
    
    var indexPath: IndexPath?
    var quiz: Quiz?
    var tableView: UITableView?
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if questionTextArea.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        questionTextArea.tag = 0
        updateCell(height: 96)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if questionTextArea.text.isEmpty {
            textView.text = LocalizedStrings.TextViewText.Title
            textView.textColor = UIColor.lightGray
        }
        if questionTextArea.tag == 0 {
            updateCell(height: nil)
        }
        quiz?.questions[indexPath!.section].title = textView.text
    }
    
    private func updateCell(height: CGFloat?) {
        if indexPath != nil, questionTextArea.text != nil {
            expandableCellDelegate?.updateCell(at: indexPath!, height: height)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
        
    }
    
}
