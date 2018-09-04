//
//  NotificationSettingsTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/22/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class NotificationSettingsTableViewController: UITableViewController {
    @IBOutlet weak var invitationSwitch: UISwitch!
    @IBOutlet weak var quizSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.NavigationBarItemTitles.NotificationSettings
        invitationSwitch.isOn = UserDefaults.standard.bool(forKey: UserDefaultsKeys.Settings.ChannelInvitations)
        quizSwitch.isOn = UserDefaults.standard.bool(forKey: UserDefaultsKeys.Settings.QuizPosted)
    }

    // MARK: - Table view data source

    @IBAction func invitationSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.Settings.ChannelInvitations)
    }
    
    @IBAction func quizSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.Settings.QuizPosted)
    }
    
}
