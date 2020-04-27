//
//  JoinChannelViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase

class JoinChannelTableViewController: UIEmptyStateTableViewController, UIPopoverPresentationControllerDelegate {
    
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
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = LocalizedStrings.SearchBarText.SearchChannels
        self.navigationItem.searchController = searchController
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
        definesPresentationContext = true
        tabBarController?.tabBar.isHidden = true
        if #available(iOS 13.0, *) {
            let navBarAppearance = GeneralUtils.navBarAppearance
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
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
        
        let channel = findChannelInTableView(by: indexPath)
        cell.textLabel?.text = channel.title
        if let channelOwner = users.filter({ $0.userId == channel.ownerId }).first {
            cell.detailTextLabel?.text = channelOwner.userName
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        let channel = findChannelInTableView(by: indexPath)
        performSegue(withIdentifier: "Show Channel Info", sender: channel)
    }
    
    override var emptyStateTitleString: String {
        return "No available channels"
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    private func filterChannelsFor(_ searchText: String) {
        filteredChannels = availableChannels.filter({ $0.title.lowercased().contains(searchText.lowercased()) })
        self.reloadDataWithEmptyState()
    }
    
    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private var filteringChannels: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private func findChannelInTableView(by indexPath: IndexPath) -> Channel {
        return filteringChannels
            ? filteredChannels[indexPath.row]
            : availableChannels[indexPath.row]

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
        case "Show Channel Info":
            if let destination = segue.destination.contents as? ChannelInfoTableViewController, let channel = sender as? Channel {
                destination.channel = channel
                destination.userChannelIds = userChannelIds
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
