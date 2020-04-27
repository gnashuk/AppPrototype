//
//  NotificationsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/24/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class NotificationsTableViewController: UIEmptyStateTableViewController {
    
    var notificationsByDates = [(date: Date, notifications: [Notification])]()
    
    private lazy var notificationsReference = FirebaseReferences.usersReference.child(user.uid).child("notifications")
    private var notificationsHandle: DatabaseHandle?
    
    private let user = Auth.auth().currentUser!
    
    deinit {
        if let handle = notificationsHandle {
            notificationsReference.removeObserver(withHandle: handle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        if #available(iOS 13.0, *) {
            let navBarAppearance = GeneralUtils.navBarAppearance
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        notificationsHandle = observeUserNotifications()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return notificationsByDates.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationsByDates[section].notifications.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Notification Cell", for: indexPath)

        let notification = notificationsByDates[indexPath.section].notifications[indexPath.row]
        if let invitation = notification as? ChannelInvitationNotification {
            cell.textLabel?.text = LocalizedStrings.LabelTexts.Channelinvitation
            let attributedText = GeneralUtils.createBoldAttributedString(string: invitation.senderName, fontSize: 12)
            attributedText.append(NSAttributedString(string: LocalizedStrings.AttributedStrings.ChannelInvitation))
            attributedText.append(GeneralUtils.createBoldAttributedString(string: invitation.channelTitle, fontSize: 12))
            cell.detailTextLabel?.attributedText = attributedText
        } else if let quizNotification = notification as? QuizNotification {
            cell.textLabel?.text = LocalizedStrings.LabelTexts.QuizAvailable
            let attributedText = NSMutableAttributedString(string: LocalizedStrings.AttributedStrings.Quiz)
            attributedText.append(GeneralUtils.createBoldAttributedString(string: quizNotification.quizTitle, fontSize: 12))
            attributedText.append(NSAttributedString(string: LocalizedStrings.AttributedStrings.WasAddedIn))
            attributedText.append(GeneralUtils.createBoldAttributedString(string: quizNotification.channelTitle, fontSize: 12))
            cell.detailTextLabel?.attributedText = attributedText
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return notificationsByDates[section].date.shortStringLocalized
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notificationsByDates[indexPath.section].notifications[indexPath.row]
        let notificationRef = self.notificationsReference.child(notification.id)
        if let invitation = notification as? ChannelInvitationNotification {
            let alert = UIAlertController(
                title: LocalizedStrings.AlertTitles.ConfirmSubscription,
                message: String.localizedStringWithFormat(LocalizedStrings.AlertMessages.ConfirmSubscription, invitation.channelTitle),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { action in
                let userRef = FirebaseReferences.usersReference.child(self.user.uid).child("channelIds")
                userRef.observe(.value) { snapshot in
                    if var userData = snapshot.value as? [String] {
                        if !userData.contains(invitation.channelId) {
                            userData.append(invitation.channelId)
                        }
                        userRef.setValue(userData)
                    } else {
                        userRef.setValue([invitation.channelId])
                    }
                    userRef.removeAllObservers()
                }

                let channelRef = FirebaseReferences.channelsReference.child(invitation.channelId).child("userIds")
                channelRef.observe(.value) { snapshot in
                    if var channelData = snapshot.value as? [String] {
                        if !channelData.contains(self.user.uid) {
                            channelData.append(self.user.uid)
                        }
                        channelRef.setValue(channelData)
                    } else {
                        channelRef.setValue([self.user.uid])
                    }
                    channelRef.removeAllObservers()
                }

                notificationRef.removeValue()
                
                self.removeNotification(at: indexPath)
                
                self.tabBarController?.selectedIndex = 0
            })
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        } else if let quizNotification = notification as? QuizNotification {
            let alert = UIAlertController(
                title: LocalizedStrings.AlertTitles.BeginQuiz,
                message: String.localizedStringWithFormat(LocalizedStrings.AlertMessages.BeginQuiz, quizNotification.quizTitle),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { action in
                let quizRef = FirebaseReferences.usersReference.child(quizNotification.senderId).child("quizes").child(quizNotification.quizId)
                let query = quizRef.queryOrderedByKey()
                query.observe(.value) { [weak self] snapshot in
                    if let quiz = Quiz.createFrom(dataSnapshot: snapshot) {
                        self?.removeNotification(at: indexPath)
                        notificationRef.removeValue()
                        quizRef.removeAllObservers()
                        self?.performSegue(withIdentifier: "Show Quiz Session", sender: (quiz, quizNotification.senderId))
                    }
                }
            })
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override var emptyStateTitleString: String {
        return "No notifications"
    }
    
    private func removeNotification(at indexPath: IndexPath) {
        if self.notificationsByDates[indexPath.section].notifications.count > 1 {
            self.notificationsByDates[indexPath.section].notifications.remove(at: indexPath.row)
        } else {
            self.notificationsByDates.remove(at: indexPath.section)
        }
        tableView.reloadData()
    }
    
    private func observeUserNotifications() -> DatabaseHandle {
        return notificationsReference.observe(.childAdded) { snapshot in
            if let notificationContent = snapshot.value as? [String: String] {
                if let dateString = notificationContent["date"], let date = dateString.convertToShortDate() {
                    
                    if let invitationNotification = ChannelInvitationNotification.createFrom(dataSnapshot: snapshot), UserDefaults.standard.bool(forKey: UserDefaultsKeys.Settings.ChannelInvitations) {
                        self.sort(invitationNotification, with: date)
                    } else if let quizNotification = QuizNotification.createFrom(dataSnapshot: snapshot), UserDefaults.standard.bool(forKey: UserDefaultsKeys.Settings.QuizPosted) {
                        self.sort(quizNotification, with: date)
                    }
                    self.reloadDataWithEmptyState()
                }
            }
        }
    }
    
    @IBAction func backToNotifications(bySegue: UIStoryboardSegue) {
    }

    @IBAction func clearAllPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: LocalizedStrings.AlertTitles.ClearAll,
            message: LocalizedStrings.AlertMessages.ClearAll,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .destructive) { action in
            for (_, notifications) in self.notificationsByDates {
                for notification in notifications {
                    self.notificationsReference.child(notification.id).removeValue()
                }
            }
            self.notificationsByDates = []
        })
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
        present(alert, animated: true)
    }
    
    private func sort(_ notification: Notification, with date: Date) {
        var notificationsOnThisDate: (date: Date, notifications: [Notification]) = (date, [])
        if let existingPair = self.notificationsByDates.filter({ self.datesEqualWithDayGranularity(date1: date, date2: $0.date) }).first {
            notificationsOnThisDate = existingPair
        }
        notificationsOnThisDate.notifications.insert(notification, at: 0)
        if self.notificationsByDates.filter({ self.datesEqualWithDayGranularity(date1: date, date2: $0.date) }).isEmpty {
            self.notificationsByDates.append(notificationsOnThisDate)
            self.notificationsByDates.sort { $0.date > $1.date }
        }
    }
    
    private func datesEqualWithDayGranularity(date1: Date, date2: Date) -> Bool {
        return NSCalendar.current.compare(date1, to: date2, toGranularity: .day) == .orderedSame
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Quiz Session" {
            if let destination = segue.destination.contents as? QuizSessionTableViewController {
                if let (quiz, senderId) = sender as? (Quiz, String) {
                    quiz.resetAnswers()
                    destination.quiz = quiz
                    destination.channelOwnerId = senderId
                    destination.launchedFromNotification = true
                }
            }
        }
    }

}
