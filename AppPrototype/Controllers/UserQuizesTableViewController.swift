//
//  UserQuizesTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/15/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import UIEmptyState

class UserQuizesTableViewController: UIEmptyStateTableViewController {
    
    var users = [User]()
    
    private let user = Auth.auth().currentUser!
    
    private lazy var userQuizesReference = FirebaseReferences.usersReference.child(user.uid).child("quizes")
    private var quizesHandle: DatabaseHandle?
    
    private var quizes = [Quiz]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.NavigationBarItemTitles.Quizes
        quizesHandle = observeQuizResults()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Quiz Cell", for: indexPath)

        let quiz = quizes[indexPath.row]
        cell.textLabel?.text = quiz.title
        cell.detailTextLabel?.text = String.localizedStringWithFormat(LocalizedStrings.LabelTexts.ResponsesCount, quiz.results.count)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let quiz = quizes[indexPath.row]
        performSegue(withIdentifier: "Show Quiz Results", sender: quiz)
    }
    
    override var emptyStateTitleString: String {
        return "You have not created any quizes"
    }
    
    private func observeQuizResults() -> DatabaseHandle {
        return userQuizesReference.observe(.childAdded) { [weak self] snapshot in
            if let quizContent = snapshot.value as? [String: Any], let quiz = Quiz.createFrom(dataSnapshot: snapshot) {
                if let results = quizContent["results"] as? [String: [String: Any]] {
                    for (_, resultContent) in results {
                        if let senderId = resultContent["senderId"] as? String, let senderName = resultContent["senderName"] as? String, let dateString = resultContent["date"] as? String, let answers = resultContent["answers"] as? [String: [String]] {
                            if let date = dateString.convertToShortDate() {
                                quiz.results.append(QuizResult(id: snapshot.key, senderId: senderId, senderName: senderName, date: date, answers: answers))
                            }
                        }
                    }
                }
                self?.quizes.append(quiz)
                self?.reloadDataWithEmptyState()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Quiz Results" {
            if let destination = segue.destination.contents as? QuizResultsTableViewController {
                if let quiz = sender as? Quiz {
                    destination.quiz = quiz
                    destination.users = users
                }
            }
        }
    }

}
