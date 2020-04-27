//
//  QuizCreatorMainTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class QuizCreatorMainTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, QuizBackButtonDelegate {
    
    private lazy var usersQuizesReference = FirebaseReferences.usersReference.child(userId).child("quizes")
    private var userQuizesHandles: DatabaseHandle?
    private let userId = Auth.auth().currentUser!.uid
    private var allQuizTitles = [String]()
    
    var quiz: Quiz?
    var channel: Channel?
    
    private lazy var pickerData = createPickerData()
    
    private var questionCount = 0 {
        didSet {
            questionCountLabel.text = String.localizedStringWithFormat(LocalizedStrings.LabelTexts.QuestionCount, questionCount)
        }
    }
    
    @IBOutlet weak var quizTitleTextField: UITextField!
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var questionCountLabel: UILabel!
    
    @IBAction func quizTypeChanged(_ sender: UISegmentedControl) {
        quiz?.type = sender.selectedSegmentIndex == 0 ? .singleChoice : .multipleChoice
        if let question = quiz?.questions {
            question.forEach({ $0.answers.forEach({ $0.correct = false }) })
        }
    }
    
    @IBAction func questionCountChanged(_ sender: UIStepper) {
        questionCount = Int(sender.value)
        if let questions = quiz?.questions {
            if questions.count < questionCount {
                quiz?.questions.append(QuizQuestion())
            } else if questions.count > questionCount {
                _ = quiz?.questions.popLast()
            }
        }
    }

    @IBAction func nextPressed(_ sender: Any) {
        quizTitleTextField.resignFirstResponder()
        if let title = quizTitleTextField.text {
            if title.isEmpty {
                quizTitleTextField.setBorder(color: UIColor.red, width: 1.25)
            } else if allQuizTitles.contains(title.lowercased()) {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.DuplicateTitle, message: LocalizedStrings.AlertMessages.DuplicateTitle)
                present(alert, animated: true)
            } else if questionCount == 0 {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.InsufficientQuestionCount, message: LocalizedStrings.AlertMessages.InsufficientQuestionCount)
                present(alert, animated: true)
            } else {
                performSegue(withIdentifier: "Show Questions", sender: nil)
            }
        }
    }
    
    @IBOutlet weak var timerPicker: UIPickerView!
    
    deinit {
        if let handle = userQuizesHandles {
            usersQuizesReference.removeObserver(withHandle: handle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        if #available(iOS 13.0, *) {
            let navBarAppearance = GeneralUtils.navBarAppearance
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        timerPicker.delegate = self
        timerPicker.dataSource = self
        quizTitleTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        view.addGestureRecognizer(tapGesture)
        userQuizesHandles = observeUserQuizes()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row > 0 {
            let words = pickerData[pickerView.selectedRow(inComponent: component)].split(separator: " ", maxSplits: 2)
            quiz?.timeLimit = .minutes(Int(words[0])!)
        } else {
            quiz?.timeLimit = .none
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.setBorder(color: UIColor.gray, width: 1.0)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            quiz?.title = text
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        quizTitleTextField.resignFirstResponder()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Questions" {
            if let destination = segue.destination.contents as? QuizCreatorQuestionsTableViewController {
                if quiz == nil {
                    let type: QuizType = typeSegmentedControl.selectedSegmentIndex == 0 ? .singleChoice : .multipleChoice
                    var timeLimit: TimeLimit = .none
                    if timerPicker.selectedRow(inComponent: 0) > 0 {
                        let words = pickerData[timerPicker.selectedRow(inComponent: 0)].split(separator: " ", maxSplits: 2)
                        timeLimit = .minutes(Int(words[0])!)
                    }
                    quiz = Quiz(title: quizTitleTextField.text!, type: type, timeLimit: timeLimit, numberOfQuestions: questionCount)
                }
                destination.quiz = quiz
                destination.channel = channel
                destination.backDelegate = self
                destination.title = quiz?.title
            }
        }
    }
    
    func resetQuiz() {
        quiz = nil
    }
    
    private func observeUserQuizes() -> DatabaseHandle {
        return usersQuizesReference.observe(.childAdded) { [weak self] snapshot in
            if let quizData = snapshot.value as? [String: Any] {
                self?.allQuizTitles.append((quizData["title"] as! String).lowercased())
            }
        }
    }
    
    private func createPickerData() -> [String] {
        var data = [LocalizedStrings.PickerViewDataItems.None, LocalizedStrings.PickerViewDataItems.Minute]
        let minuteCounts = [2, 5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 90, 105, 120]
        for count in minuteCounts {
            data.append(String.localizedStringWithFormat(LocalizedStrings.PickerViewDataItems.Minutes, count))
        }
        return data
    }
}

extension UITextField {
    func setBorder(color: UIColor, width: CGFloat) {
        self.textColor = color
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder!, attributes: [NSAttributedStringKey.foregroundColor: color])
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.setNeedsLayout()
    }
}
