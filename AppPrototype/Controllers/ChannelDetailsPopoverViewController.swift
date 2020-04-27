//
//  ChannelDetailsPopoverViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/13/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

/*
 * 04/25/2020: DEPRECATED
 * Functionality provided by JoinChannelTableViewController
 */
class ChannelDetailsPopoverViewController: UIViewController {
    
    @IBOutlet weak var topLevelView: UIStackView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var channelDescriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var channelOwnerNameLabel: UILabel!
    
    var channel: Channel?
    private var profileImageURL: URL?
    private var channelOwnerName: String? {
        didSet {
            channelOwnerNameLabel.text = channelOwnerName
        }
    }
    
    private lazy var userReference = FirebaseReferences.usersReference.child(channel!.ownerId)
    private var userHandle: DatabaseHandle?
    
    deinit {
        if let handle = userHandle {
            userReference.removeObserver(withHandle: handle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        channelNameLabel.text = channel?.title
        channelDescriptionLabel.text = channel?.description
        userHandle = observeUser()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = topLevelView?.sizeThatFits(UILayoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 60, height: fittedSize.height + 60)
        }
    }
    
    private func observeUser() -> DatabaseHandle {
        return userReference.observe(.value) { [weak self] snapshot in
            if let userContent = snapshot.value as? [String: Any], var user = User.createFrom(dataSnapshot: snapshot) {
                self?.channelOwnerName = user.userName
                if let profileImageURL = userContent["profileImageURL"] as? String {
                    user.profileImageURL = profileImageURL
                }
                self?.fetchProfileImage(user: user)
            }
        }
    }
    
    private func fetchProfileImage(user: User) {
        if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
            GeneralUtils.fetchImage(from: url) { image, error in
                DispatchQueue.main.async {
                    if image != nil && error == nil {
                        self.profileImageView.image = image
                    } else {
                        self.setPlaceholderProfileImage(user: user)
                    }
                }
            }
        } else {
            setPlaceholderProfileImage(user: user)
        }
    }
    
    private func setPlaceholderProfileImage(user: User) {
        let initials = GeneralUtils.getInitials(for: user.userName)
        let image = GeneralUtils.createLabeledImage(width: 40, height: 40, text: initials, fontSize: 24, labelBackgroundColor: .lightGray, labelTextColor: .white)
        self.profileImageView.image = image
    }
}
