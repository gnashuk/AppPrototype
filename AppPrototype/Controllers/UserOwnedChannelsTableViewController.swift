//
//  UserOwnedChannelsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class UserOwnedChannelsTableViewController: UIEmptyStateTableViewController {
    
    var channels = [Channel]()
    
    private let user = Auth.auth().currentUser!
    
    private lazy var channelsReference = FirebaseReferences.channelsReference
    private var channelsHandle: DatabaseHandle?
    
    deinit {
        if let handle = channelsHandle {
            channelsReference.removeObserver(withHandle: handle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.NavigationBarItemTitles.Channels
        channelsHandle = observeUserChannels()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Channel Cell", for: indexPath)

        let channel = channels[indexPath.row]
        cell.textLabel?.text = channel.title
        cell.detailTextLabel?.text = "Member count: \(channel.userIds?.count ?? 0)"

        return cell
    }
    
    override var emptyStateTitleString: String {
        return "You do not own any channels"
    }
    
    private func observeUserChannels() -> DatabaseHandle {
        let userOwnedChannelsQuery = channelsReference.queryOrdered(byChild: "ownerId").queryEqual(toValue: user.uid)
        
        return userOwnedChannelsQuery.observe(.childAdded) { [weak self] snapshot in
            if let channelContent = snapshot.value as? [String: Any], let channel = Channel.createForm(dataSnapshot: snapshot) {
                if let userIds = channelContent["userIds"] as? [String] {
                    channel.userIds = userIds
                }
                self?.channels.append(channel)
                self?.reloadDataWithEmptyState()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
