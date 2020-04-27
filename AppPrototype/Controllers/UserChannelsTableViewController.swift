//
//  ChannelTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import UIEmptyState

class UserChannelsTableViewController: UIEmptyStateTableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.layer.masksToBounds = true
            self.navigationItem.titleView = profileImageView
        }
    }
    
    var senderName: String?
    private var allChannels = [Channel]()
    private var userChannels: [Channel] {
        return allChannels.filter({ userChannelIds.contains($0.id) })
    }
    private var userChannelIds = [String]()
    private var users = [User]()
    
    private let userId = Auth.auth().currentUser!.uid
    
    private lazy var allChannelsReference = FirebaseReferences.channelsReference
    private var channelsHandle: DatabaseHandle?
    
    private lazy var usersReference = FirebaseReferences.usersReference
    private var usersHandle: DatabaseHandle?
    private var userChannelIdsHandle: DatabaseHandle?
    private var userProfileImageURLHandler: DatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        channelsHandle = observeChannels()
        userChannelIdsHandle = observeUserChannelIds()
        usersHandle = observeUsers()
        userProfileImageURLHandler = observeProfileImageChange()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.title = ""
        tabBarController?.tabBar.isHidden = false
        fetchProfileImage()
    }
    
    deinit {
        if let channelsHandle = channelsHandle {
            allChannelsReference.removeObserver(withHandle: channelsHandle)
        }
        if let usersHandle = usersHandle {
            usersReference.removeObserver(withHandle: usersHandle)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userChannels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Channel", for: indexPath)

        let channel = userChannels[indexPath.row]
        cell.textLabel?.text = channel.title
        if let channelOwner = users.filter({ $0.userId == channel.ownerId }).first {
            cell.detailTextLabel?.text = channelOwner.userName
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = userChannels[indexPath.row]
        performSegue(withIdentifier: "Show Chat", sender: channel)
    }
    
    override var emptyStateTitle: NSAttributedString {
        let headingAttributes = [NSAttributedStringKey.foregroundColor: UIColor.gray,NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22)]
        let descriptionAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black,
                                     NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18),
                                     NSAttributedStringKey.baselineOffset: -5] as [NSAttributedStringKey : Any]

        let heading = NSMutableAttributedString(string: "You have no subscriptions\n", attributes: headingAttributes)
        let description = NSMutableAttributedString(string: "Press \"＋\" to join or create a channel", attributes: descriptionAttributes)

        let combination = NSMutableAttributedString()

        combination.append(heading)
        combination.append(description)
        
        return combination
    }
    
    override var emptyStateButtonTitle: NSAttributedString? {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white,
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        return NSAttributedString(string: "Join Channel", attributes: attrs)
    }
    
    override var emptyStateButtonSize: CGSize? {
        return CGSize(width: 120, height: 40)
    }
    
    override func emptyStateViewWillShow(view: UIView) {
        guard let emptyView = view as? UIEmptyStateView else { return }
        emptyView.button.layer.cornerRadius = 5
        emptyView.button.layer.borderWidth = 1
        emptyView.button.layer.borderColor = UIColor.appThemeColor.cgColor
        emptyView.button.layer.backgroundColor = UIColor.appThemeColor.cgColor
    }
    
    override func emptyStatebuttonWasTapped(button: UIButton) {
        performSegue(withIdentifier: "Join Group", sender: nil)
    }
    
    @IBAction func creationDone(bySegue: UIStoryboardSegue) {
    }
    
    @objc private func touchProfileImage(_ recognizer: UITapGestureRecognizer) {
        self.tabBarController?.selectedIndex = 3
    }
    
    private func observeChannels() -> DatabaseHandle {
        return allChannelsReference.observe(.childAdded) { [weak self] snapshot in
            if let channelContent = snapshot.value as? [String: Any], let channel = Channel.createForm(dataSnapshot: snapshot) {
                if let userIds = channelContent["userIds"] as? [String] {
                    channel.userIds = userIds
                }
                self?.allChannels.append(channel)
                self?.tableView.reloadData()
                self?.reloadEmptyState()
            }
        }
    }
    
    private func observeUsers() -> DatabaseHandle {
        return usersReference.observe(.childAdded) { [weak self] snapshot in
            if let usersContent = snapshot.value as? [String: Any] {
                if var user = User.createFrom(dataSnapshot: snapshot) {
                    let profileImageURL = usersContent["profileImageURL"] as? String
                    user.profileImageURL = profileImageURL
                    self?.users.append(user)
                }
            }
        }
    }
    
    private func observeProfileImageChange() -> DatabaseHandle {
        return usersReference.child(userId).child("profileImageURL").observe(.value) { [weak self] snapshot in
            self?.fetchProfileImage()
        }
    }
    
    private func observeUserChannelIds() -> DatabaseHandle {
        return usersReference.child(userId).child("channelIds").observe(.childAdded) { [weak self] snapshot in
            if let channelIds = snapshot.value as? String {
                self?.userChannelIds.append(channelIds)
                self?.reloadDataWithEmptyState()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "Show Chat":
            if let destination = segue.destination.contents as? ChatViewController, let channel = sender as? Channel {
                destination.channel = channel
                destination.channelReference = allChannelsReference.child(channel.id)
                destination.senderDisplayName = senderName
                destination.title = channel.title
                destination.users = users
            }
        case "Join Group":
            if let destination = segue.destination.contents as? JoinChannelTableViewController {
                destination.allChannels = allChannels
                destination.userChannelIds = userChannelIds
                destination.users = users
            }
        default: break
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
}
