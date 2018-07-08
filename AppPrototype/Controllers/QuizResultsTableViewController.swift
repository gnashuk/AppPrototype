//
//  QuizResultsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/1/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class QuizResultsTableViewController: UITableViewController {
    
    var quiz: Quiz!
    var users = [User]()
    private var quizResults = [QuizResult]()
    
    private lazy var quizResultsReference = FirebaseReferences.usersReference.child(userId).child("quizes").child(quiz.id!).child("results")
    private var quizResultsHandle: DatabaseHandle?
    
    private let userId = Auth.auth().currentUser!.uid
    
    deinit {
        if let handle = quizResultsHandle {
            quizResultsReference.removeObserver(withHandle: handle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        quizResultsHandle = observeQuizResults()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Quiz Result Cell", for: indexPath)

        if let resultCell = cell as? QuizResultTableViewCell {
            let quizResult = quizResults[indexPath.row]
            if let profileImageUrl = users.filter({ $0.userId == quizResult.senderId }).first?.profileImageURL, let url = URL(string: profileImageUrl) {
                GeneralUtils.fetchImage(from: url) { image in
                    DispatchQueue.main.async {
                        resultCell.profileImageView.image = image
                    }
                }
            } else {
                let initials = GeneralUtils.getInitials(for: quizResult.senderName)
                let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
                resultCell.profileImageView.image = image
            }
            resultCell.userNameLabel.text = quizResult.senderName
            resultCell.dateLabel.text = quizResult.date.shortString
            resultCell.resultLabel.text = createResultString(for: quizResult, in: quiz)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let quizResult = quizResults[indexPath.row]
        performSegue(withIdentifier: "Show Detailed Results", sender: quizResult)
    }
    
    private func observeQuizResults() -> DatabaseHandle {
        return quizResultsReference.observe(.childAdded) { [weak self] snapshot in
            if let resultContent = snapshot.value as? [String: Any] {
                if let senderId = resultContent["senderId"] as? String, let senderName = resultContent["senderName"] as? String, let dateString = resultContent["date"] as? String, let answers = resultContent["answers"] as? [String: [String]] {
                    if let date = dateString.convertToShortDate() {
                        self?.quizResults.append(QuizResult(id: snapshot.key, senderId: senderId, senderName: senderName, date: date, answers: answers))
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func createResultString(for result: QuizResult, in quiz: Quiz) -> String {
        var maxPoints = 0
        var score = 0
        for question in quiz.questions {
            for answer in question.answers {
                if answer.correct {
                    maxPoints += 1
                    if let answersToQuestion = result.answers[question.title], answersToQuestion.contains(answer.text) {
                        score += 1
                    }
                }
            }
        }
        return "\(score)/\(maxPoints)"
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Detailed Results" {
            if let destination = segue.destination.contents as? QuizSessionTableViewController {
                if let quizResult = sender as? QuizResult {
                    destination.quiz = quiz
                    destination.quizResult = quizResult
                }
            }
        }
    }

}
