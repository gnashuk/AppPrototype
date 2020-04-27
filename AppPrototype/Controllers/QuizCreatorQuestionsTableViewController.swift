//
//  QuizCreatorTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import BEMCheckBox

protocol QuizBackButtonDelegate {
    func resetQuiz()
}

class QuizCreatorQuestionsTableViewController: UITableViewController, CollapsibleTableViewHeaderDelegate, ExpandableCellDelegate, AnswerCellDelegate {
    
    private lazy var usersQuizesReference = FirebaseReferences.usersReference.child(userId).child("quizes")
    private let userId = Auth.auth().currentUser!.uid
    
    var quiz: Quiz?
    var channel: Channel?
    
    private let user = Auth.auth().currentUser!
    
    private var expandedCellIndices: [IndexPath: CGFloat] = [:]
    private var checkBoxesGrouped: [Int: BEMCheckBoxGroup] = [:]
    
    var backDelegate: QuizBackButtonDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        let headerNib = UINib.init(nibName: "CollapsibleTableViewHeader", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "CollapsibleTableViewHeader")
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: LocalizedStrings.NavigationBarItemTitles.Back, style: UIBarButtonItemStyle.plain, target: self, action: #selector(QuizCreatorQuestionsTableViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: LocalizedStrings.AlertTitles.SaveProgress, message: LocalizedStrings.AlertMessages.SaveProgress, preferredStyle: .alert)
        let keepAction = UIAlertAction(title: LocalizedStrings.AlertActions.Keep, style: .default) { [weak self] action in
            self?.navigationController?.popViewController(animated: true)
        }
        let discardAction = UIAlertAction(title: LocalizedStrings.AlertActions.Discard, style: .destructive) { [weak self] action in
            self?.backDelegate?.resetQuiz()
            self?.navigationController?.popViewController(animated: true)
        }
        alert.addAction(keepAction)
        alert.addAction(discardAction)
        present(alert, animated: true)
    }

    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        if verifyQuiz(), let quiz = quiz {
            let alert = UIAlertController(title: LocalizedStrings.AlertTitles.FinishCreation, message: LocalizedStrings.AlertMessages.ChooseAction, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Save, style: .default) { [weak self] handler in
                _ = self?.saveQuizToFirebase(quiz: quiz)
                self?.performSegue(withIdentifier: "Creation Done", sender: nil)
            })
            
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.SaveAndPost, style: .default) { [weak self] handler in
                if let quizId = self?.saveQuizToFirebase(quiz: quiz) {
                    self?.postQuizInChannel(quizId: quizId)
                    self?.performSegue(withIdentifier: "Creation Done", sender: nil)
                }
            })
            
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return quiz?.questions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let question = quiz?.questions[section], !question.collapsed {
            let minRowCount = 2
            return question.answers.count + minRowCount
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CollapsibleTableViewHeader") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "CollapsibleTableViewHeader")

        header.titleLabel.text = String.localizedStringWithFormat(LocalizedStrings.LabelTexts.QuestionNumber, section + 1)
        header.setCollapsed(quiz?.questions[section].collapsed ?? false)

        header.section = section
        header.delegate = self
        
        return header
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Question Cell", for: indexPath) as! QuestionTitleTableViewCell
            cell.quiz = quiz
            cell.tableView = tableView
            cell.indexPath = indexPath
            cell.expandableCellDelegate = self
            if let title = quiz?.questions[section].title, !title.isEmpty {
                cell.questionTextArea.text = title
                cell.questionTextArea.textColor = UIColor.black
            }
            return cell
        case getLastIndex(in: section):
            let cell = tableView.dequeueReusableCell(withIdentifier: "New Answer Cell", for: indexPath) as! NewQuizAnswerTableViewCell
            cell.quiz = quiz
            cell.tableView = tableView
            cell.indexPath = indexPath
            cell.addButton.isEnabled = false
            cell.expandableCellDelegate = self
            cell.answerCellDelegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Answer Cell", for: indexPath) as! QuizAnswerTableViewCell
            cell.quiz = quiz
            cell.indexPath = indexPath
            if let quiz = quiz {
                let answer = quiz.questions[section].answers[row - 1]
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
                cell.checkBox.on = answer.correct
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? QuizAnswerTableViewCell {
            cell.didSelectCell()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func getLastIndex(in section: Int) -> Int {
        return quiz!.questions[section].answers.count + 1
    }
    
    private func verifyQuiz() -> Bool {
        if let questions = quiz?.questions {
            if questions.filter({ $0.title.isEmpty }).count > 0 {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.MissingTitles, message: LocalizedStrings.AlertMessages.MissingTitles)
                present(alert, animated: true)
                return false
            }
            
            let uniqueQuestionTitles = Set(questions.map { $0.title.lowercased() } )
            if uniqueQuestionTitles.count < questions.count {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.DuplicateQuestions, message: LocalizedStrings.AlertMessages.DuplicateQuestions)
                present(alert, animated: true)
                return false
            }
            
            for question in questions {
                if question.answers.count == 0 {
                    let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.MissingAnswers, message: LocalizedStrings.AlertMessages.MissingAnswers)
                    present(alert, animated: true)
                    return false
                }
                
                if question.answers.filter({ $0.correct == true }).isEmpty {
                    let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.MissingCorrertAnswers, message: LocalizedStrings.AlertMessages.MissingCorrectAnswers)
                    present(alert, animated: true)
                    return false
                }
            }
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = expandedCellIndices[indexPath] {
            return height
        } else if indexPath.row > 0 && indexPath.row < getLastIndex(in: indexPath.section) {
            return UITableViewAutomaticDimension
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        if let questions = quiz?.questions {
            let collapsed = !questions[section].collapsed
      
            questions[section].collapsed = collapsed
            header.setCollapsed(collapsed)

            tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
        }
    }

    func updateCell(at indexPath: IndexPath, height: CGFloat?) {
        expandedCellIndices[indexPath] = height
    }
    
    func presentAlert(title: String, message: String) {
        let alert = Alerts.createSingleActionAlert(title: title, message: message)
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.row > 0 && indexPath.row < getLastIndex(in: indexPath.section) {
            let editAction = UITableViewRowAction(style: .normal, title: LocalizedStrings.TableViewRowActions.Edit) { [weak self] (action, indexPath) in
                if let answer = self?.deleteAnswerCell(at: indexPath), let row = self?.getLastIndex(in: indexPath.section), let cell = tableView.cellForRow(at: IndexPath(item: row, section: indexPath.section)) as? NewQuizAnswerTableViewCell {
                    cell.answerText = answer
                }
            }
            
            let deleteAction = UITableViewRowAction(style: .destructive, title: LocalizedStrings.TableViewRowActions.Delete) { [weak self] (action, indexPath) in
                _ = self?.deleteAnswerCell(at: indexPath)
            }
            return [deleteAction, editAction]
        }
        
        return nil
    }
    
    private func deleteAnswerCell(at indexPath: IndexPath) -> String? {
        if let question = self.quiz?.questions[indexPath.section] {
            let answer = question.answers.remove(at: indexPath.row - 1)
            if #available(iOS 11.0, *) {
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                })
            } else {
                tableView.reloadData()
            }
            return answer.text
        }
        return nil
    }
    
    private func postQuizInChannel(quizId: String) {
        if let channelId = channel?.id, let displayName = user.displayName {
            let messagesRef = FirebaseReferences.channelsReference.child(channelId).child("messages")
            let newMessageRef = messagesRef.childByAutoId()
            
            let messageValue: [String: Any] = [
                "senderId": user.uid,
                "senderName": displayName,
                "quizId": quizId,
                "date": Date().longString
            ]
            
            newMessageRef.setValue(messageValue)
            sendUserNotifications(quizId: quizId)
        }
    }
    
    private func sendUserNotifications(quizId: String) {
        if let channelId = channel?.id, let channelTitle = channel?.title, let userIds = channel?.userIds, let quizTitle = quiz?.title {
            for userId in userIds where userId != user.uid {
                let notificationsRef = FirebaseReferences.usersReference.child(userId).child("notifications")
                let newNotificationRef = notificationsRef.childByAutoId()
                
                let notificationValue: [String: Any] = [
                    "date": Date().shortString,
                    "channelId": channelId,
                    "channelTitle": channelTitle,
                    "quizId": quizId,
                    "quizTitle": quizTitle,
                    "senderId": user.uid
                ]
                
                newNotificationRef.setValue(notificationValue)
            }
        }
    }
    
    private func saveQuizToFirebase(quiz: Quiz) -> String {
        let newQuizReference = usersQuizesReference.childByAutoId()
        let quizValue: [String: Any] = [
            "title": quiz.title,
            "type": String(describing: quiz.type),
            "timeLimit": quiz.timeLimit.description
        ]
        
        newQuizReference.setValue(quizValue)
        saveQuestionsToFirebase(reference: newQuizReference, questions: quiz.questions)
        
        return newQuizReference.key
    }
    
    private func saveQuestionsToFirebase(reference: DatabaseReference, questions: [QuizQuestion]) {
        let questionsReference = reference.child("questions")
        for question in questions {
            let newQuestionReference = questionsReference.childByAutoId()
            let questionValue = [
                "title": question.title
            ]
            newQuestionReference.setValue(questionValue)
            saveAnswersToFirebase(reference: newQuestionReference, answers: question.answers)
        }
        
    }
    
    private func saveAnswersToFirebase(reference: DatabaseReference, answers: [QuizAnswer]) {
        let answersReference = reference.child("answers")
        for answer in answers {
            let newAnswerReference = answersReference.childByAutoId()
            let answerValue: [String: Any] = [
                "text": answer.text,
                "correct": answer.correct
            ]
            newAnswerReference.setValue(answerValue)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
