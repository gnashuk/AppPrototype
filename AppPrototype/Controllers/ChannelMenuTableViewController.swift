//
//  ChannelMenuTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/16/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChannelMenuTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var menuBarButton: UIBarButtonItem?
    var ownerOptions: Bool = false
    var channel: Channel?
    
    private let currentUser = Auth.auth().currentUser!
    private lazy var usersReference = FirebaseReferences.usersReference

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var height = 44
        if ownerOptions {
            height *= 2
        } else {
            
        }
        preferredContentSize = CGSize(width: 300, height: height)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Option Cell", for: indexPath)

        if ownerOptions {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LocalizedStrings.LabelTexts.ManageChannels
            case 1:
                cell.textLabel?.text = LocalizedStrings.LabelTexts.CreateQuiz
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = LocalizedStrings.LabelTexts.ShowChannelInfo
            default:
                break
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ownerOptions {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "Show Channel Details", sender: nil)
            case 1:
                performSegue(withIdentifier: "Show Quiz Creator", sender: nil)
                presentingViewController?.popoverPresentationController?.sourceView?.isHidden = true
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "Show Channel Details", sender: nil)
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Quiz Creator" {
            if let destination = segue.destination.contents as? QuizCreatorMainTableViewController {
                destination.channel = channel
            }
        } else if segue.identifier == "Show Channel Details" {
            if let destination = segue.destination.contents as? ChannelDetailsTableViewController {
                destination.channel = channel
                if ownerOptions {
                    destination.ownerDisplayName = currentUser.displayName
                    destination.ownerProfileImageURL = currentUser.photoURL
                } else {
                    let userQuery = usersReference.child(channel!.ownerId).queryOrderedByKey()
                    userQuery.observe(.value) { snapshot in
                        if let userContent = snapshot.value as? [String: Any] {
                            if let userName = userContent["userName"] as? String {
                                destination.ownerDisplayName = userName
                            }
                            if let imageUrlString = userContent["profileImageURL"] as? String {
                                if let imageUrl = URL(string: imageUrlString) {
                                    destination.ownerProfileImageURL = imageUrl
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
