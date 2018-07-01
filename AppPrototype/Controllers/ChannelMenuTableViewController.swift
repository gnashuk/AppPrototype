//
//  ChannelMenuTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/16/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class ChannelMenuTableViewController: UITableViewController {
    
    var ownerOptions: Bool = false
    var channel: Channel?

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
                cell.textLabel?.text = "Manage Channel"
            case 1:
                cell.textLabel?.text = "Create Quiz"
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Show Channel Info"
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
                break
            case 1:
                performSegue(withIdentifier: "Show Quiz Creator", sender: nil)
                presentingViewController?.popoverPresentationController?.sourceView?.isHidden = true
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                break
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Quiz Creator" {
            if let destination = segue.destination.contents as? QuizCreatorMainTableViewController {
                destination.channel = channel
            }
        }
    }

}
