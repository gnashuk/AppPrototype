//
//  CreateChannelViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class CreateChannelViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var channels: [Channel]?
    var userChannelIds = [String]()
    var allUsers = [User]()
    var selectedUsers = [User]()
    
    private lazy var channelsReference = FirebaseReferences.channelsReference
    private lazy var usersReference = FirebaseReferences.usersReference
    private var userChannelsHandle: DatabaseHandle?
    private var usersHandle: DatabaseHandle?
    
    private let user = Auth.auth().currentUser!
    private let descriptionPlaceholder = "Description (Optional)"

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var privateSwitch: UISwitch!
    @IBOutlet weak var inviteesCollectionView: UICollectionView!
    
    private lazy var nonUniqueTitleAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Non-unique Channel Title",
            message: "Channel with such title already exists.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        return alert
    }()
    
    private lazy var emptyUniqueTitleAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Empty Channel Title",
            message: "Please provide a channel title.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        return alert
    }()
    
    deinit {
        if let handle = userChannelsHandle {
            usersReference.removeObserver(withHandle: handle)
        }
        if let handle = usersHandle {
            usersReference.removeObserver(withHandle: handle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionTextView.delegate = self
        titleTextField.delegate = self
        descriptionTextView.text = descriptionPlaceholder
        descriptionTextView.textColor = UIColor.lightGray
        descriptionTextView.layer.cornerRadius = 5.0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        view.addGestureRecognizer(tapGesture)
        userChannelsHandle = observeUserChannels()
        usersHandle = observeUsers()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = inviteesCollectionView.dequeueReusableCell(withReuseIdentifier: "User Image Cell", for: indexPath)
        
        if let userCell = cell as? UserImageCollectionViewCell {
            let user = selectedUsers[indexPath.item]
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                GeneralUtils.fetchImage(from: url) { image in
                    DispatchQueue.main.async {
                        userCell.profileImageView.image = image
                    }
                }
            } else {
                let initials = GeneralUtils.getInitials(for: user.userName)
                let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
                userCell.profileImageView.image = image
            }
        }
        
        return cell
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        if let title = titleTextField.text, !title.isEmpty {
            if isChannelTitleUnique(title: title) {
                let newChannelReference = channelsReference.childByAutoId()
                
                let channelValue: [String: Any] = [
                    "title" : title,
                    "ownerId": user.uid,
                    "description": channelDescription,
                    "isPrivate": privateSwitch.isOn
                ]
                newChannelReference.setValue(channelValue)
                
                userChannelIds.append(newChannelReference.key)
                usersReference.child(user.uid).child("channelIds").setValue(userChannelIds)
                sendUserInvitation(channelId: newChannelReference.key, channelTitle: title)
                performSegue(withIdentifier: "Creation Done", sender: sender)
            } else {
                present(nonUniqueTitleAlert, animated: true)
            }
        } else {
            present(emptyUniqueTitleAlert, animated: true)
        }
    }
    
    private func sendUserInvitation(channelId: String, channelTitle: String) {
        for selectedUser in selectedUsers {
            let notificationsRef = FirebaseReferences.usersReference.child(selectedUser.userId).child("notifications")
            let newNotificationRef = notificationsRef.childByAutoId()
            
            let notificationValue: [String: Any] = [
                "date": Date().shortString,
                "channelId": channelId,
                "channelTitle": channelTitle,
                "senderName": user.displayName!
            ]
            
            newNotificationRef.setValue(notificationValue)
        }
    }
    
    @IBAction func userSelectionDone(bySegue: UIStoryboardSegue) {
    }
    
    private var channelDescription: String {
        if let description = descriptionTextView.text, descriptionTextView.textColor == UIColor.black {
            return description
        }
        return ""
    }
    
    private func observeUserChannels() -> DatabaseHandle {
        return usersReference.child(user.uid).child("channelIds").observe(.childAdded) { [weak self] snapshot in
            if let channelIds = snapshot.value as? String {
                self?.userChannelIds.append(channelIds)
            }
        }
    }
    
    private func observeUsers() -> DatabaseHandle {
        return usersReference.observe(.childAdded) { [weak self] snapshot in
            if let userData = snapshot.value as? [String: Any] {
                if var user = User.createFrom(dataSnapshot: snapshot) {
                    user.profileImageURL = userData["profileImageURL"] as? String
                    self?.allUsers.append(user)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Invite Users" {
            if let destination = segue.destination.contents as? UserInvitationsTableViewController {
                destination.allUsers = allUsers
                destination.selectedUsers = selectedUsers
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        titleTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionTextView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextView.text.isEmpty {
            descriptionTextView.text = descriptionPlaceholder
            descriptionTextView.textColor = UIColor.lightGray
        }
    }
    
    private func isChannelTitleUnique(title: String) -> Bool {
        if let channels = channels {
            for channel in channels {
                if title == channel.title {
                    return false
                }
            }
        }
        return true
    }
}
