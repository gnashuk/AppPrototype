//
//  JoinChannelViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class JoinChannelTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var allChannels = [Channel]()
    var userChannelIds = [String]()
    var users = [User]()
    
    private lazy var availableChannels = {
        return allChannels.filter({ !userChannelIds.contains($0.id) && $0.ownerId != userId && !$0.isPrivate })
    }()
    private var filteredChannels = [Channel]()
    
    private let userId = Auth.auth().currentUser!.uid
    private lazy var usersReference = FirebaseReferences.usersReference
    
    private lazy var channelsReference = FirebaseReferences.channelsReference

    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Channels"
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
    
    @IBAction func cancelChannelCreation(bySegue: UIStoryboardSegue) {
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteringChannels {
            return filteredChannels.count
        }
        
        return availableChannels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Channel", for: indexPath)
        
        let channel: Channel
        if filteringChannels {
            channel = filteredChannels[indexPath.row]
        } else {
            channel = availableChannels[indexPath.row]
        }
        cell.textLabel?.text = channel.title
        if let channelOwner = users.filter({ $0.userId == channel.ownerId }).first {
            cell.detailTextLabel?.text = channelOwner.userName
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        let channel: Channel
        if filteringChannels {
            channel = filteredChannels[indexPath.row]
        } else {
            channel = availableChannels[indexPath.row]
        }
        let alert = UIAlertController(
            title: "Confirm Subscription",
            message: "Do you want to join the channel \(channel.title)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] action in
            self?.userChannelIds.append(channel.id)
            self?.usersReference.child((self?.userId)!).child("channelIds").setValue(self?.userChannelIds)
            
            if let userId = self?.userId {
                var userIds = channel.userIds ?? []
                userIds.append(userId)
                self?.channelsReference.child(channel.id).child("userIds").setValue(userIds)
            }
            self?.performSegue(withIdentifier: "Subscription Done", sender: nil)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let channel: Channel
        if filteringChannels {
            channel = filteredChannels[indexPath.row]
        } else {
            channel = availableChannels[indexPath.row]
        }
        
        if let channelDetailsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Channel Details VC") as? ChannelDetailsPopoverViewController {
            if let cell = tableView.cellForRow(at: indexPath) {
                let accessoryButton = findDisclosureButton(in: cell)
                channelDetailsVC.modalPresentationStyle = .popover
                channelDetailsVC.popoverPresentationController?.delegate = self
                channelDetailsVC.popoverPresentationController?.sourceView = accessoryButton
                channelDetailsVC.popoverPresentationController?.sourceRect = accessoryButton!.frame
                
                channelDetailsVC.channel = channel
                present(channelDetailsVC, animated: true)
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    private func filterChannelsFor(_ searchText: String) {
        filteredChannels = availableChannels.filter({ $0.title.lowercased().contains(searchText.lowercased()) })
        tableView.reloadData()
    }
    
    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private var filteringChannels: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private func findDisclosureButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton {
            return button
        } else {
            if view.subviews.count > 0 {
                for subview in view.subviews {
                    if let result = findDisclosureButton(in: subview) {
                        return result
                    }
                }
            }
        }
        return nil;
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "Create Channel":
            if let destination = segue.destination.contents as? CreateChannelViewController {
                destination.channels = allChannels
            }
        default: break
        }
    }

}

extension JoinChannelTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterChannelsFor(searchText)
        }
    }
    
    
}
