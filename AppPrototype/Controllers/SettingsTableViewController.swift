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
            profileImageActivityIndicator.startAnimating()
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
    
    @IBOutlet weak var profileImageActivityIndicator: UIActivityIndicatorView!
    
    private let storageReference = FirebaseReferences.storageReference
    private var firebaseUser = Auth.auth().currentUser!
    
    private var users = [User]()
    
    private var currentUserObject: User? {
        return users.filter({ $0.userId == firebaseUser.uid }).first
    }
    
    private lazy var usersReference = FirebaseReferences.usersReference
    private var usersHandle: DatabaseHandle?
    
    deinit {
        if let handle = usersHandle {
            usersReference.removeObserver(withHandle: handle)
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
        usersHandle = observeUsers()
    }
    
    @objc private func touchProfileImage(_ recognizer: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Camera, style: .default) { [weak self] handler in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                imagePicker.sourceType = .camera
            } else {
                imagePicker.sourceType = .photoLibrary
            }
            self?.present(imagePicker, animated: true)
        })
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.PhotoLibrary, style: .default) { [weak self] handler in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self?.present(imagePicker, animated: true)
        })
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.ViewImage, style: .default) { [weak self] handler in
            if let image = self?.profileImageView.image {
                let photoProvider = PhotoProvider(image: image)
                let photosViewController = photoProvider.photoViewer
                self?.present(photosViewController, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.RemoveImage, style: .default) { [weak self] handler in
            let alert = UIAlertController(title: LocalizedStrings.AlertTitles.RemoveProfileImage, message: LocalizedStrings.AlertMessages.RemoveProfileImage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .destructive) { [weak self] handler in
                if let changeRequest = self?.firebaseUser.createProfileChangeRequest() {
                    self?.deleteCurrentUserImageInStorage()
                    changeRequest.photoURL = URL(string: "no_image")
                    changeRequest.commitChanges(completion: { error in
                        self?.commitImageChangesCompletion(storagePath: nil, successMessage: LocalizedStrings.AlertMessages.RemoveProfileImage, error: error)
                    })
                }
            })
            alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
            
            self?.present(alert, animated: true)
        })
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
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
                            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.ErrorOccured, message: err.localizedDescription)
                            self?.present(alert, animated: true)
                        } else {
                            let user = Auth.auth().currentUser!
                            self?.usersReference.child(user.uid).child("userName").setValue(user.displayName)
                            self?.firebaseUser = user
                            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.ChangeSaved, message: String.localizedStringWithFormat(LocalizedStrings.AlertMessages.NameChangeSaved, user.displayName!))
                            self?.present(alert, animated: true)
                        }
                    }
                } else {
                    let alert = UIAlertController(title: LocalizedStrings.AlertTitles.EmptyNameField, message: LocalizedStrings.AlertMessages.EmptyNameField, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Ok, style: .default) { [weak self] handler in
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
                performSegue(withIdentifier: "Show User Channels", sender: nil)
            case 1:
                performSegue(withIdentifier: "Show User Quizes", sender: nil)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "Show Notification Settings", sender: nil)
            case 1:
                do {
                    try Auth.auth().signOut()
                    performSegue(withIdentifier: "Log Out", sender: nil)
                } catch let error {
                    let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.LogOutError, message: error.localizedDescription)
                    present(alert, animated: true)
                }
            case 2:
                let deleteAlert = UIAlertController(title: "Account Deletion", message: "Do you want to delete this user account?", preferredStyle: .alert)
                deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] action in
                    let confirmAlert = UIAlertController(title: "Confirm Removal", message: "Are you sure you want to permanently remove user account?", preferredStyle: .alert)
                    confirmAlert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .destructive) { [weak self] action in
                        if let user = self?.firebaseUser {
                            user.delete { [weak self] error in
                                if let error = error {
                                    let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                                    self?.present(alert, animated: true)
                                    return
                                }
                                self?.usersReference.child(user.uid).removeValue()
                            }
                        }
                    })
                    confirmAlert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
                    
                    self?.present(confirmAlert, animated: true)
                })
                deleteAlert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
                
                present(deleteAlert, animated: true)
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
            GeneralUtils.fetchImage(from: url) { image, error in
                DispatchQueue.main.async {
                    if image != nil && error == nil {
                        self.profileImageView.image = image
                    } else {
                        self.setPlaceholderProfileImage()
                    }
                    self.profileImageActivityIndicator.stopAnimating()
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
            self.profileImageActivityIndicator.stopAnimating()
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
                
                profileImageActivityIndicator.startAnimating()
                storageReference.child(imagePath).putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                    if let error = error {
                        let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.ErrorOccured, message: error.localizedDescription)
                        self?.present(alert, animated: true)
                        return
                    }
                    self?.deleteCurrentUserImageInStorage()
                    if let path = metadata?.path, let storageRef = self?.storageReference, let url = URL(string: storageRef.child(path).description), let firebaseUser = self?.firebaseUser {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.photoURL = url
                        changeRequest.commitChanges { [weak self] error in
                            self?.commitImageChangesCompletion(storagePath: storageRef.child(path).description, successMessage: LocalizedStrings.AlertMessages.ImageChangeSaved, error: error)
                            
                        }
                    }
                }
            }
        }
    }
    
    private func deleteCurrentUserImageInStorage() {
        if let currentURL = Auth.auth().currentUser?.photoURL, currentURL.absoluteString.hasPrefix("gs://") {
            let ref = Storage.storage().reference(forURL: currentURL.absoluteString)
            ref.delete(completion: nil)
        }
    }
    
    private func commitImageChangesCompletion(storagePath: String?, successMessage: String, error: Error?) {
        if let err = error {
            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.ErrorOccured, message: err.localizedDescription)
            present(alert, animated: true)
        } else {
            let user = Auth.auth().currentUser!
            firebaseUser = user
            if var currentUserObject = self.currentUserObject {
                currentUserObject.profileImageURL = storagePath
            }
            fetchProfileImage()
            usersReference.child(user.uid).child("profileImageURL").setValue(storagePath)
            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.ChangeSaved, message: successMessage)
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
