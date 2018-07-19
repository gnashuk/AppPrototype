//
//  SettingsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/8/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import NYTPhotoViewer

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            fetchProfileImage()
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.layer.masksToBounds = true
            profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchProfileImage(_:))))
        }
    }
    @IBOutlet weak var displayNameTextField: UITextField! {
        didSet {
            displayNameTextField.borderStyle = .none
            displayNameTextField.text = firebaseUser.displayName
            displayNameTextField.delegate = self
        }
    }
    @IBOutlet weak var editImageView: UIImageView! {
        didSet {
            editImageView.isUserInteractionEnabled = true
            editImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchEditImage(_:))))
        }
    }

    private let storageReference = FirebaseReferences.storageReference
    private var firebaseUser = Auth.auth().currentUser!
    
    private var users = [User]()
    
    private var currentUserObject: User? {
        return users.filter({ $0.userId == firebaseUser.uid }).first
    }
    
    private lazy var usersReference = FirebaseReferences.usersReference
    private var usersHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usersHandle = observeUsers()
    }
    
    @objc private func touchProfileImage(_ recognizer: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] handler in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                imagePicker.sourceType = .camera
            } else {
                imagePicker.sourceType = .photoLibrary
            }
            self?.present(imagePicker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] handler in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self?.present(imagePicker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "View Image", style: .default) { [weak self] handler in
            if let image = self?.profileImageView.image {
                let photoProvider = PhotoProvider(image: image)
                let photosViewController = photoProvider.photoViewer
                self?.present(photosViewController, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Remove Image", style: .default) { [weak self] handler in
            let alert = UIAlertController(title: "Remove Profile Image", message: "Are you sure you want to delete user profile image?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] handler in
                if let changeRequest = self?.firebaseUser.createProfileChangeRequest() {
                    self?.deleteCurrentUserImageInStorage()
                    changeRequest.photoURL = URL(string: "no_image")
                    changeRequest.commitChanges(completion: { error in
                        self?.commitImageChangesCompletion(storagePath: nil, successMessage: "Profile image was succesfully deleted.", error: error)
                    })
                }
                
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self?.present(alert, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func touchEditImage(_ recognizer: UITapGestureRecognizer) {
        if displayNameTextField.isEnabled {
            if let text = displayNameTextField.text, !text.isEmpty && text != firebaseUser.displayName {
                if !text.isEmpty {
                    let changeRequest = firebaseUser.createProfileChangeRequest()
                    changeRequest.displayName = text
                    changeRequest.commitChanges { [weak self] error in
                        if let err = error {
                            let alert = Alerts.createSingleActionAlert(title: "Error Occured", message: err.localizedDescription)
                            self?.present(alert, animated: true)
                        } else {
                            let user = Auth.auth().currentUser!
                            self?.usersReference.child("userName").setValue(user.displayName)
                            self?.firebaseUser = user
                            let alert = Alerts.createSingleActionAlert(title: "Change Saved", message: "User display name was successfuly changed to \(user.displayName!).")
                            self?.present(alert, animated: true)
                        }
                    }
                } else {
                    let alert = UIAlertController(title: "Empty Name Field", message: "User name field can't be empty.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] handler in
                        if let displayName = self?.firebaseUser.displayName {
                            self?.displayNameTextField.text = displayName
                        }
                    })
                    present(alert, animated: true)
                }
            }
            displayNameTextField.isEnabled = false
            displayNameTextField.borderStyle = .none
            displayNameTextField.resignFirstResponder()
            editImageView.image = UIImage(named: "pencil")
        } else {
            displayNameTextField.isEnabled = true
            displayNameTextField.borderStyle = .roundedRect
            displayNameTextField.becomeFirstResponder()
            editImageView.image = UIImage(named: "ok")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            break
        case 1:
            switch indexPath.row {
            case 0:
                break
            case 1:
                performSegue(withIdentifier: "Show User Quizes", sender: nil)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                break
            case 1:
                do {
                    try Auth.auth().signOut()
                    performSegue(withIdentifier: "Log Out", sender: nil)
                } catch let error {
                    let alert = Alerts.createSingleActionAlert(title: "Log Out Error", message: error.localizedDescription)
                    present(alert, animated: true)
                }
            case 2:
                break
            default:
                break
            }
        default:
            break
        }
    }
    
    private func observeUsers() -> DatabaseHandle {
        return usersReference.observe(.childAdded) { [weak self] snapshot in
            if let userContent = snapshot.value as? [String: Any], var user = User.createFrom(dataSnapshot: snapshot) {
                user.channelIds = userContent["channelIds"] as? [String]
                user.profileImageURL = userContent["profileImageURL"] as? String
                self?.users.append(user)
            }
        }
    }
    
    private func fetchProfileImage() {
        if let url = Auth.auth().currentUser?.photoURL {
            let imageURL = url.absoluteString
            if imageURL.hasPrefix("gs://") {
                let imageStorageRef = Storage.storage().reference(forURL: imageURL)
                imageStorageRef.downloadURL { url, error in
                    if url != nil {
                        GeneralUtils.fetchImage(from: url!) { image, error in
                            DispatchQueue.main.async {
                                if image != nil && error == nil {
                                    self.profileImageView.image = image
                                } else {
                                    self.setPlaceholderProfileImage()
                                }
                            }
                        }
                    }
                }
            } else {
                GeneralUtils.fetchImage(from: url) { image, error in
                    DispatchQueue.main.async {
                        if image != nil && error == nil {
                            self.profileImageView.image = image
                        } else {
                            self.setPlaceholderProfileImage()
                        }
                    }
                }
            }
        } else {
            setPlaceholderProfileImage()
        }
    }
    
    private func setPlaceholderProfileImage() {
        if let displayName = Auth.auth().currentUser?.displayName {
            let initials = GeneralUtils.getInitials(for: displayName)
            let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
            self.profileImageView.image = image
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                let imagePath = "\(firebaseUser.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = StorageMetadata()
                metadata.contentType = "image/type"
                
                storageReference.child(imagePath).putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                    if let error = error {
                        let alert = Alerts.createSingleActionAlert(title: "Error Occured", message: error.localizedDescription)
                        self?.present(alert, animated: true)
                        return
                    }
                    self?.deleteCurrentUserImageInStorage()
                    if let path = metadata?.path, let storageRef = self?.storageReference, let url = URL(string: storageRef.child(path).description), let firebaseUser = self?.firebaseUser {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.photoURL = url
                        changeRequest.commitChanges { [weak self] error in
                            self?.commitImageChangesCompletion(storagePath: storageRef.child(path).description, successMessage: "User profile image was successfuly changed.", error: error)
                            
                        }
                    }
                }
            }
        }
    }
    
    private func deleteCurrentUserImageInStorage() {
        if let currentURL = Auth.auth().currentUser?.photoURL {
            let ref = Storage.storage().reference(forURL: currentURL.absoluteString)
            ref.delete(completion: nil)
        }
    }
    
    private func commitImageChangesCompletion(storagePath: String?, successMessage: String, error: Error?) {
        if let err = error {
            let alert = Alerts.createSingleActionAlert(title: "Error Occured", message: err.localizedDescription)
            present(alert, animated: true)
        } else {
            let user = Auth.auth().currentUser!
            firebaseUser = user
            if var currentUserObject = self.currentUserObject {
                currentUserObject.profileImageURL = storagePath
            }
            fetchProfileImage()
            usersReference.child("profileImageURL").setValue(storagePath)
            let alert = Alerts.createSingleActionAlert(title: "Change Saved", message: successMessage)
            present(alert, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show User Quizes" {
            if let destination = segue.destination.contents as? UserQuizesTableViewController {
                destination.users = users
            }
        }
    }
}
