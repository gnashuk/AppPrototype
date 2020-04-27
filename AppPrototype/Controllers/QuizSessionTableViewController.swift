//
//  QuizSessionTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/27/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import BEMCheckBox
import Firebase

class QuizSessionTableViewController: UITableViewController, CollapsibleTableViewHeaderDelegate {
    
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    var quiz: Quiz?
    var channelOwnerId: String?
    var quizResult: QuizResult? {
        didSet {
            submitButton.isEnabled = false
            navigationController?.navigationItem.rightBarButtonItem?.tintColor = UIColor.clear
            tableView.allowsSelection = false
        }
    }
    var launchedFromNotification = false
    
    private lazy var usersReference = FirebaseReferences.usersReference
    let currentUser = Auth.auth().currentUser
    
    private var checkBoxesGrouped: [Int: BEMCheckBoxGroup] = [:]
    
    private var countdownTimer: Timer?
    private var timerSecondsCount = 0
    
    private var backgroundColorByIndexPath = [IndexPath: UIColor]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let headerNib = UINib.init(nibName: "CollapsibleTableViewHeader", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "CollapsibleTableViewHeader")
        setTimer()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return quiz?.questions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let question = quiz?.questions[section], !question.collapsed {
            let minRowCount = 1
            return question.answers.count + minRowCount
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Question Cell", for: indexPath)
            cell.textLabel?.text = quiz?.questions[section].title
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Answer Cell", for: indexPath) as! QuizAnswerTableViewCell
            cell.quiz = quiz
            cell.indexPath = indexPath
            if let quiz = quiz {
                let question = quiz.questions[section]
                let answer = question.answers[row - 1]
                let answerText = NSMutableAttributedString(string: answer.text)
                let attributedText = GeneralUtils.createBoldAttributedString(string: "\(Array("abcdefghijklmnopqrstuvwxyz".characters)[row - 1])) ", fontSize: 17)
                attributedText.append(answerText)
                cell.answerLabel?.attributedText = attributedText
                
                if quiz.type == .singleChoice {
                    cell.checkBox.boxType = .circle
                    if let boxGroup = checkBoxesGrouped[section] {
                        boxGroup.addCheckBox(toGroup: cell.checkBox)
                    } else {
                        checkBoxesGrouped[section] = BEMCheckBoxGroup(checkBoxes: [cell.checkBox])
                    }
                } else {
                    cell.checkBox.boxType = .square
                }
                if let quizResult = quizResult {
                    if let userAnswers = quizResult.answers[question.title] {
                        cell.answerBackgroundView.backgroundColor = getBackgroundColor(for: indexPath, quizAnswer: answer, userAnswers: userAnswers)
                        cell.checkBox.on = userAnswers.contains(answer.text)
                    } else {
                        cell.checkBox.on = false
                    }
                    cell.checkBox.isEnabled = false
                } else {
                    cell.checkBox.on = answer.correct
                }
            }
            return cell
        }

    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CollapsibleTableViewHeader") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "CollapsibleTableViewHeader")
        
        header.titleLabel.text = String.localizedStringWithFormat(LocalizedStrings.LabelTexts.QuestionNumber, section + 1)
        header.setCollapsed(quiz?.questions[section].collapsed ?? false)
        
        header.section = section
        header.delegate = self
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? QuizAnswerTableViewCell {
            cell.didSelectCell()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        if let questions = quiz?.questions {
            let collapsed = !questions[section].collapsed
            
            questions[section].collapsed = collapsed
            header.setCollapsed(collapsed)
            
            tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
        }
    }
    
    private func setTimer() {
        if quizResult != nil {
            timerLabel.isHidden = true
        } else {
            if let timeLimit = quiz?.timeLimit {
                switch timeLimit {
                case .none:
                    timerLabel.text = nil
                case .minutes(let minutes):
                    timerSecondsCount = minutes * 60
                    countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(tick(timer:)), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    @objc private func tick(timer: Timer) {
        timerSecondsCount -= 1
        if timerSecondsCount < 0 {
            if let countdownTimer = countdownTimer, let quiz = quiz {
                countdownTimer.invalidate()
                saveQuizResultToFirebase(quiz: quiz)
                let alert = UIAlertController(title: LocalizedStrings.AlertTitles.QuizOver, message: LocalizedStrings.AlertMessages.QuizOver, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Ok, style: .default) { [weak self] handler in
                    self?.finishQuizAndPerformSegue()
                })
                present(alert, animated: true)
            }
        } else {
            let seconds: Int = timerSecondsCount % 60
            let minutes: Int = (timerSecondsCount / 60) % 60
            let hours: Int = timerSecondsCount / 3600
            timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }

    @IBAction func didPressSubmit(_ sender: UIBarButtonItem) {
        if let quiz = quiz {
            let alert = UIAlertController(title: LocalizedStrings.AlertTitles.FinishQuiz, message: LocalizedStrings.AlertMessages.FinishQuiz, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { [weak self] handler in
                self?.saveQuizResultToFirebase(quiz: quiz)
                self?.finishQuizAndPerformSegue()
            })
            
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        }
        
    }
    
    private func saveQuizResultToFirebase(quiz: Quiz) {
        if let channelOwnerId = channelOwnerId, let quizId = quiz.id {
            let quizResultsRef = usersReference.child(channelOwnerId).child("quizes").child(quizId).child("results")
            let newResultRef = quizResultsRef.childByAutoId()
            
            var results = [String: Any]()
            for question in quiz.questions {
                let selectedAnswers = question.answers.filter({ $0.correct }).map({ $0.text })
                if !selectedAnswers.isEmpty {
                    results[question.title] = selectedAnswers
                }
            }
            
            let resultValue: [String: Any] = [
                "senderId": currentUser!.uid,
                "senderName": currentUser!.displayName!,
                "date": Date().shortString,
                "answers": results
            ]
            
            newResultRef.setValue(resultValue)
        }
    }
    
    private func finishQuizAndPerformSegue() {
        if launchedFromNotification {
            performSegue(withIdentifier: "Back to Notifications", sender: nil)
        } else {
            performSegue(withIdentifier: "Quiz Submitted", sender: nil)
        }
    }
    
    private func getBackgroundColor(for indexPath: IndexPath, quizAnswer: QuizAnswer, userAnswers: [String]) -> UIColor {
        if let color = backgroundColorByIndexPath[indexPath] {
            return color
        } else {
            if quizAnswer.correct {
                backgroundColorByIndexPath[indexPath] = UIColor.green
                return backgroundColorByIndexPath[indexPath]!
            } else {
                if userAnswers.contains(quizAnswer.text) {
                    backgroundColorByIndexPath[indexPath] = UIColor.red
                    return backgroundColorByIndexPath[indexPath]!
                }
            }
        }
        return UIColor.white
    }

}
