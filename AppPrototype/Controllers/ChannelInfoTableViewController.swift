//
//  ChannelInfoTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 4/25/20.
//  Copyright © 2020 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
//import FirebaseStorage

class ChannelInfoTableViewController: ChannelDetailsTableViewController {
    
    var userChannelIds = [String]()
    
    private let currentUser = Auth.auth().currentUser!
    
    private let channelsReference = FirebaseReferences.channelsReference
    private lazy var usersReference = FirebaseReferences.usersReference
    private lazy var userReference = FirebaseReferences.usersReference.child(channel!.ownerId)
    private var userHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        userHandle = observeUser()
        super.viewDidLoad()
    }
    
    deinit {
        if let handle = userHandle {
            userReference.removeObserver(withHandle: handle)
        }
    }
    
    override func initializeBarItem() {
        titleTextField.isUserInteractionEnabled = false
        descriptionTextView.isUserInteractionEnabled = false
        saveBarButton.title = LocalizedStrings.NavigationBarItemTitles.Join
        saveBarButton.isEnabled = true
    }
    
    override func handleBarButtonPress() {
        if let channel = channel {
            let alert = UIAlertController(
                title: LocalizedStrings.AlertTitles.ConfirmSubscription,
                message: String.localizedStringWithFormat(LocalizedStrings.AlertMessages.ConfirmSubscription, channel.title),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { [weak self] action in
                let userId = self?.currentUser.uid
                self?.userChannelIds.append(channel.id)
                self?.usersReference.child(userId!).child("channelIds").setValue(self?.userChannelIds)
                
                if let userId = userId {
                    var userIds = channel.userIds ?? []
                    userIds.append(userId)
                    self?.channelsReference.child(channel.id).child("userIds").setValue(userIds)
                }
                self?.performSegue(withIdentifier: "Subscription Done", sender: nil)
            })
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        }
    }
    
    private func observeUser() -> DatabaseHandle {
        return userReference.observe(.value) { [weak self] snapshot in
            if let userContent = snapshot.value as? [String: Any], let user = User.createFrom(dataSnapshot: snapshot) {
                self?.ownerDisplayName = user.userName
                self?.userDisplayNameLabel.text = user.userName
                if let profileImageURL = userContent["profileImageURL"] as? String, let imageUrl = URL(string: profileImageURL) {
                    self?.ownerProfileImageURL = imageUrl
                    
                }
                self?.fetchProfileImage()
            }
        }
    }
}
