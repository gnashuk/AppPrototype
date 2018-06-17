//
//  JoinChannelViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class JoinChannelTableViewController: UITableViewController {
    
    var allChannels = [Channel]()
    var userChannelIds = [String]()
    var users = [User]()
    
    private lazy var availableChannels = {
        return allChannels.filter({ !userChannelIds.contains($0.id) })
    }()
    private var filteredChannels = [Channel]()
    
    private let userId = Auth.auth().currentUser!.uid
    private lazy var usersReference = FirebaseReferences.usersReference

    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Channels"
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        tabBarController?.tabBar.isHidden = true
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
            title: "Confirm subscription",
            message: "Do you want to join the channel \(channel.title)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] action in
            self?.userChannelIds.append(channel.id)
            self?.usersReference.child((self?.userId)!).child("channelIds").setValue(self?.userChannelIds)
            self?.performSegue(withIdentifier: "Subscription Done", sender: nil)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("accessoryButtonTappedForRowWith \(indexPath)")
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
