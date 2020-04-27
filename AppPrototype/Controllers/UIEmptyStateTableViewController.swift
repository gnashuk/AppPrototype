//
//  UIEmptyStateTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 4/26/20.
//  Copyright © 2020 Oleg Gnashuk. All rights reserved.
//

import UIKit
import UIEmptyState

class UIEmptyStateTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.reloadEmptyState()
    }
    
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.gray,
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: emptyStateTitleString, attributes: attrs)
    }
    
    var emptyStateButtonTitle: NSAttributedString? {
        return nil
    }
    
    var emptyStateButtonSize: CGSize? {
        return nil
    }
    
    func emptyStateViewWillShow(view: UIView) {}
    
    func emptyStatebuttonWasTapped(button: UIButton) {}

    var emptyStateTitleString: String {
        return "No data"
    }
    
    func reloadDataWithEmptyState() {
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
}
