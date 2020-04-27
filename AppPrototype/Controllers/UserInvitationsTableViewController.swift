//
//  UserInvitationsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/1/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class UserInvitationsTableViewController: UITableViewController {
    
    var allUsers: [User]?
    var selectedUsers = [User]()

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
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return selectedUsers.count
        case 1:
            return allUsers?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return selectedUsers.isEmpty ? nil : LocalizedStrings.TableViewHeaderTitle.SelectedUsers
        case 1:
            if let allUsers = allUsers, !allUsers.isEmpty {
                return LocalizedStrings.TableViewHeaderTitle.AllUsers
            }
            return nil
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Username Cell", for: indexPath)

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = selectedUsers[indexPath.row].userName
            cell.accessoryType = .checkmark
        default:
            if let user = allUsers?[indexPath.row] {
                cell.textLabel?.text = user.userName
                cell.accessoryType = .none
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let user = selectedUsers.remove(at: indexPath.row)
            allUsers?.insert(user, at: 0)
            if #available(iOS 11.0, *) {
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    tableView.insertRows(at: [IndexPath(item: 0, section: 1)], with: .automatic)
                    tableView.reloadSections([0, 1], with: .automatic)
                    tableView.reloadData()
                })
            } else {
                tableView.reloadData()
            }
        case 1:
            if let user = allUsers?.remove(at: indexPath.row) {
                selectedUsers.append(user)
                if #available(iOS 11.0, *) {
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        tableView.insertRows(at: [IndexPath(item: self.selectedUsers.indices.last!, section: 0)], with: .automatic)
                        tableView.reloadSections([0, 1], with: .automatic)
                        tableView.reloadData()
                    })
                } else {
                    tableView.reloadData()
                }
            }
        default:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "User Selection Done" {
            if let destination = segue.destination.contents as? CreateChannelViewController, let allUsers = allUsers {
                destination.allUsers = allUsers
                destination.selectedUsers = selectedUsers
                destination.inviteesCollectionView.reloadData()
            }
        }
    }

}
