//
//  LoginViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import CryptoSwift
import FBSDKLoginKit
import GoogleSignIn

class LoginViewController: UIViewController, UITextFieldDelegate, FUIAuthDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var facebookLoginButton: FBSDKLoginButton!
    @IBOutlet weak var fbButtonVerticalSpacingContraint: NSLayoutConstraint!
    
    private var users = [User]()
    
    private lazy var usersReference = FirebaseReferences.usersReference
    private var usersHandle: DatabaseHandle?
    
    private lazy var authUI: FUIAuth? = {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
            FUIFacebookAuth(),
            FUITwitterAuth()
            ]
        authUI?.providers = providers
        return authUI
    }()
    
    private var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    deinit {
        print("LoginViewCOntroller deinit")
        if let handle = usersHandle {
            usersReference.removeObserver(withHandle: handle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
//        GIDSignIn.sharedInstance().signIn()
//        GIDSignIn.sharedInstance().signOut()
        emailTextField.text = "oleg_gnashuk@i.ua"
        passwordTextField.text = "O1eg@Stefan"
        usersHandle = observeUsers()
        fixFbButtonAppearance()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func login(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty {
            let loadingAlert = Alerts.createLoadingAlert(withCenterIn: view, title: "Working", message: "Please wait...", delegate: nil, cancelButtonTitle: nil)
            loadingAlert.show()
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
                loadingAlert.dismiss(withClickedButtonIndex: 0, animated: true)
                if let error = error {
                    self?.presentLoginFailedAlert(error)
                } else {
                    self?.presentChannelsViewControler(userDisplayName: result?.user.displayName)
                }
            }
        } else {
            let alert = UIAlertController(
                title: "Empty Login Field",
                message: "Email and password fields can't be empty.",
                preferredStyle: .alert
            )
            present(alert, animated: true)
        }
    }
    
    @IBAction func loginFacebook(_ sender: FBSDKLoginButton) {
    }
    
    @IBAction func loginGoogle(_ sender: GIDSignInButton) {
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        present(authUI!.authViewController(), animated: true)
    }
    
    @IBAction func forgotPassword(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Account Password Reset",
            message: "Enter the email associated with account.",
            preferredStyle: .alert
        )
        alert.addTextField()
        
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default) { [weak self] action in
                if let email = alert.textFields?.first?.text {
                    if !email.isEmpty, let view = self?.view {
                        let loadingAlert = Alerts.createLoadingAlert(withCenterIn: view, title: "Working", message: "Please wait...", delegate: nil, cancelButtonTitle: "Hide")
                        loadingAlert.show()
                        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                            loadingAlert.dismiss(withClickedButtonIndex: 0, animated: true)
                            if let error = error {
                                let errorAlert = Alerts.createSingleActionAlert(title: "Error", message: error.localizedDescription)
                                self?.present(errorAlert, animated: true)
                                return
                            }
                            let confirmAlert = Alerts.createSingleActionAlert(title: "Message Sent", message: "Password reset link was sent to the specified email.")
                            self?.present(confirmAlert, animated: true)
                        }
                    }
                }
            }
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func observeUsers() -> DatabaseHandle {
        return usersReference.observe(.childAdded) { [weak self] snapshot in
            if let user = User.createFrom(dataSnapshot: snapshot) {
                self?.users.append(user)
            }
        }
    }
    
    func firebaseLogin(_ credential: AuthCredential) {
//        if let user = Auth.auth().currentUser {
//            presentChannelsViewControler(userDisplayName: user.displayName)
//        } else {
        let loadingAlert = Alerts.createLoadingAlert(withCenterIn: view, title: "Working", message: "Please wait...", delegate: nil, cancelButtonTitle: nil)
        loadingAlert.show()
            Auth.auth().signInAndRetrieveData(with: credential) { [weak self] (authResult, error) in
                if let error = error {
                    self?.presentLoginFailedAlert(error)
                    return
                }
                
                self?.saveNewUserInFirebase(authDataResult: authResult)
                loadingAlert.dismiss(withClickedButtonIndex: 0, animated: true)
                self?.presentChannelsViewControler(userDisplayName: authResult?.user.displayName)
            }
//        }
    }
    
    private func saveNewUserInFirebase(authDataResult: AuthDataResult?) {
        if let userId = authDataResult?.user.uid, isNewUser(userId: userId) {
            let newUserReference = usersReference.child(userId)
            let userName = authDataResult?.user.displayName
            var userValue: [String: Any] = [
                "userName": userName ?? authDataResult!.user.email!
            ]
            if let profileImageURL = authDataResult?.user.photoURL?.absoluteString {
                userValue["profileImageURL"] = profileImageURL
            }
            newUserReference.setValue(userValue)
        }
    }
    
    // MARK: - Navigation
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            presentLoginFailedAlert(error)
            return
        }
        saveNewUserInFirebase(authDataResult: authDataResult)
        presentChannelsViewControler(userDisplayName: authDataResult?.user.displayName)
    }
    
    private func presentChannelsViewControler(userDisplayName: String?) {
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "Tab VC") as? UITabBarController,
           let userChannelsTVC = mainStoryboard.instantiateViewController(withIdentifier: "User Channels VC") as? UserChannelsTableViewController,
           let channelsNavigationVC = mainStoryboard.instantiateViewController(withIdentifier: "Channels Navigation VC") as? UINavigationController,
           let notificationsVC = mainStoryboard.instantiateViewController(withIdentifier: "Notifications VC") as? NotificationsTableViewController,
           let notificationsNavigationVC = mainStoryboard.instantiateViewController(withIdentifier: "Notifications Navigation VC") as? UINavigationController,
           let settingsVC = mainStoryboard.instantiateViewController(withIdentifier: "Settings VC") as? SettingsTableViewController,
           let settingsNavigationVC = mainStoryboard.instantiateViewController(withIdentifier: "Settings Navigation VC") as? UINavigationController {
                userChannelsTVC.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(named: "chat"), tag: 0)
                notificationsVC.tabBarItem = UITabBarItem(title: "Alerts", image: UIImage(named: "bell"), tag: 1)
                settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings"), tag: 2)
                tabBarController.setViewControllers([channelsNavigationVC, notificationsNavigationVC, settingsNavigationVC], animated: true)
            
                userChannelsTVC.senderName = emailTextField?.text
                userChannelsTVC.senderName = userDisplayName
                channelsNavigationVC.viewControllers = [userChannelsTVC]
                notificationsNavigationVC.viewControllers = [notificationsVC]
                settingsNavigationVC.viewControllers = [settingsVC]
                present(tabBarController, animated: true, completion: nil)
                    
            
            
        }
    }
    
    private func presentLoginFailedAlert(_ error: Error) {
        let alert = Alerts.createSingleActionAlert(title: "Login Failed", message: error.localizedDescription)
        present(alert, animated: true)
    }
    
    private func isNewUser(userId: String) -> Bool {
        return users.filter({ $0.userId == userId }).isEmpty
    }
    
    private func fixFbButtonAppearance() {
        let layoutConstraintsArr = facebookLoginButton.constraints
        for lc in layoutConstraintsArr {
            if ( lc.constant == 28 ){
                lc.isActive = false
                break
            }
        }
        facebookLoginButton.layer.cornerRadius = 4
        fbButtonVerticalSpacingContraint.constant = 12
    }

}

extension LoginViewController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            presentLoginFailedAlert(error)
            return
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        firebaseLogin(credential)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}
