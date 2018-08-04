//
//  Alerts.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/3/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class Alerts {
    static func createSingleActionAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Ok, style: .default))
        return alert
    }
    
    static func createLoadingAlert(withCenterIn view: UIView, title: String?, message: String?, delegate: Any?, cancelButtonTitle: String?) -> UIAlertView {
        let loadingAlert: UIAlertView = UIAlertView(title: title, message: message, delegate: delegate, cancelButtonTitle: cancelButtonTitle)
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 50, y: 10, width: 37, height: 37)) as UIActivityIndicatorView
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating()
        
        loadingAlert.setValue(loadingIndicator, forKey: "accessoryView")
        return loadingAlert
    }
}
