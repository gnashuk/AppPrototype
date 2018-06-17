//
//  CreateChannelViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class CreateChannelViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    var channels: [Channel]?
    var userChannelIds = [String]()
    
    private lazy var channelsReference = FirebaseReferences.channelsReference
    private lazy var usersReference = FirebaseReferences.usersReference
    private var userChannelsHandle: DatabaseHandle?
    
    private let userId = Auth.auth().currentUser!.uid
    private let descriptionPlaceholder = "Description (Optional)"

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
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
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionTextView.delegate = self
        titleTextField.delegate = self
        descriptionTextView.text = descriptionPlaceholder
        descriptionTextView.textColor = UIColor.lightGray
        descriptionTextView.layer.cornerRadius = 5.0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        userChannelsHandle = observeUserChannels()
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        if let title = titleTextField.text, !title.isEmpty {
            if isChannelTitleUnique(title: title) {
                let newChannelReference = channelsReference.childByAutoId()
                
                let channelValue = [
                    "title" : title,
                    "ownerId": userId,
                    "description": channelDescription
                ]
                newChannelReference.setValue(channelValue)
                
                userChannelIds.append(newChannelReference.key)
                usersReference.child(userId).child("channelIds").setValue(userChannelIds)
                performSegue(withIdentifier: "Creation Done", sender: sender)
            } else {
                present(nonUniqueTitleAlert, animated: true)
            }
        } else {
            present(emptyUniqueTitleAlert, animated: true)
        }
    }
    
    private var channelDescription: String {
        if let description = descriptionTextView.text, descriptionTextView.textColor == UIColor.black {
            return description
        }
        return ""
    }
    
    private func observeUserChannels() -> DatabaseHandle {
        return usersReference.child(userId).child("channelIds").observe(.childAdded) { [weak self] snapshot in
            if let channelIds = snapshot.value as? String {
                self?.userChannelIds.append(channelIds)
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
