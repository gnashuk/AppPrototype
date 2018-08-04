//
//  FileBrowserViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/20/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class FileBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIDocumentInteractionControllerDelegate {
    let documentInteractionController = UIDocumentInteractionController()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        documentInteractionController.delegate = self
        allowsDocumentCreation = false
        tabBarController?.selectedIndex = 0
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        presentDocument(at: documentURLs.first!)
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    private func presentDocument(at fileUrl: URL) {
        documentInteractionController.url = fileUrl
        documentInteractionController.presentPreview(animated: true)
    }

}
