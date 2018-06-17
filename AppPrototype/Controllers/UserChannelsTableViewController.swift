//
//  ChannelTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class UserChannelsTableViewController: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = 20
            profileImageView.layer.masksToBounds = true
            fetchProfileImage()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        channelsHandle = observeChannels()
        userChannelIdsHandle = observeUserChannelIds()
        usersHandle = observeUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        if let channelsHandle = channelsHandle {
            allChannelsReference.removeObserver(withHandle: channelsHandle)
        }
        if let usersHandle = usersHandle {
            usersReference.removeObserver(withHandle: usersHandle)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    @IBAction func creationDone(bySegue: UIStoryboardSegue) {
    }
    
    private func observeChannels() -> DatabaseHandle {
        return allChannelsReference.observe(.childAdded) { [weak self] snapshot in
            if let channelData = snapshot.value as? [String: Any] {
                if let title = channelData["title"] as? String, let ownerId = channelData["ownerId"] as? String, let description = channelData["description"] as? String, !title.isEmpty {
                    self?.allChannels.append(Channel(id: snapshot.key, title: title, ownerId: ownerId, description: description))
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func observeUsers() -> DatabaseHandle {
        return usersReference.observe(.childAdded) { [weak self] snapshot in
            if let usersContent = snapshot.value as? [String: Any] {
                if let userName = usersContent["userName"] as? String {
                    let profileImageURL = usersContent["profileImageURL"] as? String
                    self?.users.append(User(userId: snapshot.key, userName: userName, profileImageURL: profileImageURL))
                }
            }
        }
    }
    
    private func observeUserChannelIds() -> DatabaseHandle {
        return usersReference.child(userId).child("channelIds").observe(.childAdded) { [weak self] snapshot in
            if let channelIds = snapshot.value as? String {
                self?.userChannelIds.append(channelIds)
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Navigation

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
        let photoURL = Auth.auth().currentUser?.photoURL
        struct last {
            static var photoURL: URL? = nil
        }
        last.photoURL = photoURL
        if let photoURL = photoURL {
            DispatchQueue.global(qos: .default).async {
                let data = try? Data(contentsOf: photoURL)
                if let data = data {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async(execute: {
                        if photoURL == last.photoURL {
                            self.profileImageView?.image = image
                        }
                    })
                }
            }
        }

    }
}
