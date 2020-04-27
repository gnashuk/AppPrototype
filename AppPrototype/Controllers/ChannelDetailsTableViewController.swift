//
//  ChannelDetailsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 8/29/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChannelDetailsTableViewController: UITableViewController, ChannelDetailsRightBarItemHandler {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var userProfileImageView: UIImageView! {
        didSet {
            userProfileImageView.layer.cornerRadius = userProfileImageView.frame.size.width / 2
            userProfileImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var userDisplayNameLabel: UILabel!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    var channel: Channel?
    var ownerProfileImageURL: URL?
    var ownerDisplayName: String?
    
    private let currentUser = Auth.auth().currentUser!
    
    private let channelsReference = FirebaseReferences.channelsReference

    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.text = channel?.title
        descriptionTextView.text = channel?.description
        initializeBarItem()
    }

    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        handleBarButtonPress()
    }
    
    func initializeBarItem() {
        if channel!.ownerId != currentUser.uid {
            titleTextField.isUserInteractionEnabled = false
            descriptionTextView.isUserInteractionEnabled = false
            saveBarButton.isEnabled = false
        }
        userDisplayNameLabel.text = ownerDisplayName
        fetchProfileImage()
    }
    
    func handleBarButtonPress() {
        if let titleText = titleTextField.text, !titleText.isEmpty {
            let alert = UIAlertController(title: LocalizedStrings.AlertTitles.ConfirmChange, message: LocalizedStrings.AlertMessages.ConfirmChange, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { action in
                if let channelId = self.channel?.id {
                    let channelReference = self.channelsReference.child(channelId)
                    channelReference.child("title").setValue(titleText)
                    channelReference.child("description").setValue(self.descriptionTextView.text ?? "")
                    self.channel?.title = titleText
                    self.channel?.description = self.descriptionTextView.text ?? ""
                    self.performSegue(withIdentifier: "Save Changes", sender: nil)
                }
            })
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            present(alert, animated: true)
        } else {
            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.EmptyChannelTitle, message: LocalizedStrings.AlertMessages.EmptyChannelTitle)
            present(alert, animated: true)
        }
    }

    func fetchProfileImage() {
        if let url = ownerProfileImageURL {
            GeneralUtils.fetchImage(from: url) { image, error in
                DispatchQueue.main.async {
                    if image != nil && error == nil {
                        self.userProfileImageView.image = image
                    } else {
                        self.setPlaceholderProfileImage()
                    }
                }
            }
        } else {
            setPlaceholderProfileImage()
        }
    }
    
    private func setPlaceholderProfileImage() {
        if let displayName = ownerDisplayName {
            let initials = GeneralUtils.getInitials(for: displayName)
            let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
            self.userProfileImageView.image = image
        }
    }
}

protocol ChannelDetailsRightBarItemHandler {
    func initializeBarItem()
    func handleBarButtonPress()
}
