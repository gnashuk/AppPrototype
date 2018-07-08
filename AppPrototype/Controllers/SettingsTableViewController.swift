//
//  SettingsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/8/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {

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
            displayNameTextField.isEnabled = false
            displayNameTextField.borderStyle = .none
            displayNameTextField.text = firebaseUser.displayName
        }
    }
    @IBOutlet weak var editImageView: UIImageView! {
        didSet {
            editImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchEditImage(_:))))
        }
    }
    @IBOutlet weak var channelCountLabel: UILabel!
    @IBOutlet weak var quizesCountLabel: UILabel!
    
    private let firebaseUser = Auth.auth().currentUser!
    private var user: User?
    
    private lazy var userReference = FirebaseReferences.usersReference.child(firebaseUser.uid)
    private var userHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userHandle = observeUser()
    }
    
    @objc private func touchProfileImage(_ recognizer: UITapGestureRecognizer) {
        
    }
    
    @objc private func touchEditImage(_ recognizer: UITapGestureRecognizer) {
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    private func observeUser() -> DatabaseHandle {
        return userReference.observe(.childAdded) { [weak self] snapshot in
            if let userContent = snapshot.value as? [String: Any], let userObject = User.createFrom(dataSnapshot: snapshot) {
                if self?.user == nil {
                    self?.user = userObject
                    self?.user?.channelIds = userContent["channelIds"] as? [String]
                    self?.user?.profileImageURL = userContent["profileImageURL"] as? String
                }

            }
        }
    }
    
    private func fetchProfileImage() {
        if let url = Auth.auth().currentUser?.photoURL {
            GeneralUtils.fetchImage(from: url) { image in
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            }
        } else {
            if let displayName = Auth.auth().currentUser?.displayName {
                let initials = GeneralUtils.getInitials(for: displayName)
                let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
                self.profileImageView.image = image
            }
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
