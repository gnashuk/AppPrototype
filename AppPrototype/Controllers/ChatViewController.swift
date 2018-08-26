//
//  ChatViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Photos
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import JSQMessagesViewController
import NYTPhotoViewer
import MobileCoreServices
import Alamofire

class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    
    private let refreshControl = UIRefreshControl()
    private var queryLimit = 50
    
    let currentUser = Auth.auth().currentUser
    
    var channel: Channel?
    var users = [User]()
    var channelReference: DatabaseReference?
    
    private lazy var messagesReference: DatabaseReference = channelReference!.child("messages")
    private var newMessagesHandle: DatabaseHandle?
    
    private var messages = [JSQMessage]()
    private var messagesFirebaseKeys: Set<String> = Set<String>()
    private var userSentMediaByMessageId = [String: JSQPhotoMediaItem]()
    private var userProfileImages: [User: UIImage] = [:]
    
    private var selfTyping = false {
        didSet {
            if selfTyping {
                typingUserReference.setValue(true)
            } else {
                typingUserReference.removeValue()
            }
        }
    }
    private lazy var typingUserReference: DatabaseReference = channelReference!.child("typingUsers").child(self.senderId)
    private lazy var typingUsersQuery: DatabaseQuery = channelReference!.child("typingUsers").queryOrderedByKey()
    private var typingUsersHandle: DatabaseHandle?
    
    private let queue = DispatchQueue.global(qos: .background)
    private var userStoppedTypingWorkItem: DispatchWorkItem?
    
    private let storageReference = FirebaseReferences.storageReference
    
    private let fileManager = FileManager.default
    private lazy var documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.title = channel?.title
        automaticallyScrollsToMostRecentMessage = true
        senderId = Auth.auth().currentUser?.uid
        newMessagesHandle = observeNewMessages()
        tabBarController?.tabBar.isHidden = true
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchPreviousMessages(_:)), for: .valueChanged)
        documentInteractionController.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        typingUsersHandle = observeTypingUsers()
    }
    
    private func observeNewMessages() -> DatabaseHandle? {
        let query = messagesReference.queryLimited(toLast: UInt(queryLimit))
        
        return query.observe(.childAdded, with: { [weak self] (snapshot) in
            if let messageContent = snapshot.value as? [String: Any] , let messageKeys = self?.messagesFirebaseKeys, !messageKeys.contains(snapshot.key) {
                self?.messagesFirebaseKeys.insert(snapshot.key)
                if let id = messageContent["senderId"] as? String, let senderName = messageContent["senderName"] as? String, let dateString = messageContent["date"] as? String {
                    let messageDate = self?.convertToMessageDateFormat(dateString: dateString)
                    if let messageText = messageContent["text"] as? String, !messageText.isEmpty {
                        self?.appendMessage(senderId: id, senderName: senderName, date: messageDate, text: messageText)
                        self?.finishSendingMessage()
                    } else if let imageURL = messageContent["imageURL"] as? String {
                        if let _ = self?.userSentMediaByMessageId[snapshot.key] {
                        } else if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self?.senderId) {
                            self?.appendImageMessage(senderId: id, senderName: senderName, date: messageDate, mediaItem: mediaItem)
                            if let url = URL(string: imageURL) {
                                GeneralUtils.fetchImage(from: url) { image, error in
                                    DispatchQueue.main.async {
                                        mediaItem.image = image
                                        self?.collectionView.reloadData()
                                    }
                                }
                            }
                        }
                    } else if let quizId = messageContent["quizId"] as? String, let ownderId = self?.channel?.ownerId {
                        let quizReference = FirebaseReferences.usersReference.child(ownderId).child("quizes").child(quizId)
                        let query = quizReference.queryOrderedByKey()
                        query.observe(.value, with: { [weak self] snapshot in
                            if let quiz = Quiz.createFrom(dataSnapshot: snapshot) {
                                self?.appendQuizMessage(senderId: id, senderName: senderName, date: messageDate, quiz: quiz)
                            }
                        })
                    } else if let fileUrl = messageContent["fileUrl"] as? String, let fileSize = messageContent["fileSize"] as? String {
                        if let _ = self?.userSentMediaByMessageId[snapshot.key] {
                        } else if let url = URL(string: fileUrl), let mediaItem = self?.createFileMedia(fileUrl: url, fileSize: fileSize, senderId: id) {
                            self?.appendFileMessage(senderId: id, senderName: senderName, date: messageDate, mediaItem: mediaItem)
                        }
                    }
                    if let user = self?.users.filter({ $0.userId == id }).first, let keys = self?.userProfileImages.keys {
                        if !keys.contains(user) {
                            if let absolutePath = user.profileImageURL, let url = URL(string: absolutePath) {
                                GeneralUtils.fetchImage(from: url) { image, error in
                                    if image != nil && error == nil {
                                        DispatchQueue.main.async { [weak self] in
                                            self?.userProfileImages[user] = image
                                            self?.collectionView.reloadData()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    private func observeTypingUsers() -> DatabaseHandle? {
        return typingUsersQuery.observe(.value) { [weak self] snapshot in
            if snapshot.childrenCount > 0, let map = snapshot.value as? [String:Bool], let senderId = self?.senderId {
                if map.count == 1 && map.keys.contains(senderId) {
                    self?.showTypingIndicator = false
                } else {
                    self?.showTypingIndicator = true
                    if let visibleCells = self?.collectionView.indexPathsForVisibleItems, let messages = self?.messages, visibleCells.contains(IndexPath(item: messages.count - 1, section: 0)) {
                        self?.scrollToBottom(animated: true)
                    }
                }
            } else {
                self?.showTypingIndicator = false
            }
        }
    }
    
    private func appendMessage(senderId id: String, senderName: String, date: Date?, text: String) {
        if let message = JSQMessage(senderId: id, senderDisplayName: senderName, date: date, text: text.decrypted) {
            messages.append(message)
            messages.sort { $0.date < $1.date }
        }
    }
    
    private func appendImageMessage(senderId id: String, senderName: String, date: Date?, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, senderDisplayName: senderName, date: date, media: mediaItem) {
            messages.append(message)
            messages.sort { $0.date < $1.date }
            collectionView.reloadData()
        }
    }
    
    private func appendQuizMessage(senderId id: String, senderName: String, date: Date?, quiz: Quiz) {
        if let image = GeneralUtils.createLabeledImage(width: 200, height: 200, text: quiz.title, fontSize: 14, labelBackgroundColor: .lightGray, labelTextColor: .white), let senderId = self.senderId {
            let mediaItem = QuizMediaItem(maskAsOutgoing: id == senderId)
            mediaItem?.image = image
            mediaItem?.quiz = quiz
            appendImageMessage(senderId: id, senderName: senderName, date: date, mediaItem: mediaItem!)
        }
    }
    
    private func appendFileMessage(senderId id: String, senderName: String, date: Date?, mediaItem: JSQPhotoMediaItem) {
        appendImageMessage(senderId: id, senderName: senderName, date: date, mediaItem: mediaItem)
    }
    
    private func saveImageMessage(imageUrl url: String, reference: DatabaseReference) {
        let messageValue = [
            "senderId": senderId!,
            "imageURL": url,
            "senderName": senderDisplayName,
            "date": Date().longString
        ]
        
        reference.setValue(messageValue)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
    
    private func saveFileMessage(fileUrl url: String, fileSize: String, reference: DatabaseReference) {
        let messageValue = [
            "senderId": senderId!,
            "fileUrl": url,
            "fileSize": fileSize,
            "senderName": senderDisplayName,
            "date": Date().longString
        ]
        
        reference.setValue(messageValue)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        var messageBubbleImage: JSQMessageBubbleImageDataSource?
        if message.senderId == senderId {
            messageBubbleImage = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleRed())
        } else {
            messageBubbleImage = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        }
        
        return messageBubbleImage
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        return message.senderId == senderId ? nil : NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if isEarliest(message: message, index: indexPath.item, timeUnit: .day) {
            return NSAttributedString(string: message.date.longStringLocalized)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        if let senderId = message.senderId, let user = users.filter({ $0.userId == senderId }).first {
            if let image = userProfileImages[user] {
                return JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 34)
            }
        }
        return JSQMessagesAvatarImageFactory.avatarImage(
            withUserInitials: GeneralUtils.getInitials(for: message.senderDisplayName),
            backgroundColor: UIColor.jsq_messageBubbleLightGray(),
            textColor: UIColor.gray,
            font: UIFont.systemFont(ofSize: 18.0),
            diameter: 34
        )
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.row]
        if isEarliest(message: message, index: indexPath.item, timeUnit: .day) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.row]
        if isEarliest(message: message, index: indexPath.item, timeUnit: .day) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.media == nil && message.senderId != senderId {
            cell.textView.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if !text.isEmpty {
            let newRef = messagesReference.childByAutoId()
            
            let messageValue: [String: Any] = [
                "senderId": senderId,
                "senderName": senderDisplayName,
                "text": text.encrypted,
                "date": Date().longString
            ]
            
            newRef.setValue(messageValue)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            finishSendingMessage(animated: true)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let actionSheet = UIAlertController(title: LocalizedStrings.AlertTitles.SendMedia, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: LocalizedStrings.AlertActions.Camera, style: .default) { [weak self] (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                imagePicker.sourceType = .camera
            } else {
                imagePicker.sourceType = .photoLibrary
            }
            self?.present(imagePicker, animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: LocalizedStrings.AlertActions.PhotoLibrary, style: .default) { [weak self] (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self?.present(imagePicker, animated: true)
        }
        let documentPickerAction = UIAlertAction(title: LocalizedStrings.AlertActions.SendFile, style: .default) { [weak self] action in
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = .formSheet
            self?.present(documentPicker, animated: true)
        }
        let cancelAction = UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
        actionSheet.addAction(documentPickerAction)
        actionSheet.addAction(cancelAction)
        present(actionSheet, animated: true)
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if !textView.text.isEmpty {
            selfTyping = true
            userStoppedTypingWorkItem?.cancel()
            queue.suspend()
            userStoppedTypingWorkItem = DispatchWorkItem { [weak self] in
                self?.selfTyping = false
            }
            if userStoppedTypingWorkItem != nil && !userStoppedTypingWorkItem!.isCancelled {
                queue.asyncAfter(deadline: .now() + 5, execute: userStoppedTypingWorkItem!)
            }
        } else {
            selfTyping = false
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapCellAt indexPath: IndexPath!, touchLocation: CGPoint) {
        print("didTapCellAt: \(indexPath.item)")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        if let quizMediaItem = message.media as? QuizMediaItem, let quiz = quizMediaItem.quiz {
            if let ownerId = channel?.ownerId, let userId = currentUser?.uid, ownerId == userId {
                performSegue(withIdentifier: "Show Quiz Results", sender: quiz)
            } else {
                performSegue(withIdentifier: "Show Quiz Session", sender: quiz)
            }
        } else if let fileMediaItem = message.media as? FileMediaItem, let url = fileMediaItem.fileUrl {
            let fileName = url.absoluteString.lastPathComponent
            let destinationUrl = documentsDirectory
                .appendingPathComponent("AppPrototype")
                .appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                documentInteractionController.url = destinationUrl
                documentInteractionController.presentPreview(animated: true)
            } else {
                let alert = UIAlertController(title: LocalizedStrings.AlertTitles.DownloadFile, message: String.localizedStringWithFormat(LocalizedStrings.AlertMessages.DownloadFile, fileName), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Confirm, style: .default) { action in
                    let fileStorageReference = Storage.storage().reference(forURL: url.absoluteString)
                    let loadingAlert = Alerts.createLoadingAlert(withCenterIn: self.view, title: "Downloading", message: "Please wait...", delegate: nil, cancelButtonTitle: LocalizedStrings.AlertActions.Hide)
                    loadingAlert.show()
                    fileStorageReference.downloadURL { downloadUrl, error in
                        if let error = error {
                            let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                            self.present(alert, animated: true)
                            loadingAlert.dismiss(withClickedButtonIndex: 0, animated: true)
                            return
                        }
                        if downloadUrl != nil {
                            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                                return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
                            }
                            Alamofire.download(downloadUrl!, to: destination).response { response in
                                loadingAlert.dismiss(withClickedButtonIndex: 0, animated: true)
                            }
                        }
                    }
                })
                alert.addAction(UIAlertAction(title: LocalizedStrings.AlertActions.Cancel, style: .cancel))
                present(alert, animated: true)
            }
        } else if let photoMedia = message.media as? JSQPhotoMediaItem, let image = photoMedia.image {
            let photoProvider = PhotoProvider(image: image)
            let photosViewController = photoProvider.photoViewer
            present(photosViewController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        if let image = avatarImageView.image {
            let photoProvider = PhotoProvider(image: image)
            present(photoProvider.photoViewer, animated: true)
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleRed())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let newRef = messagesReference.childByAutoId()
            let mediaItem = JSQPhotoMediaItem(image: image)
            userSentMediaByMessageId[newRef.key] = mediaItem
            appendImageMessage(senderId: senderId, senderName: senderDisplayName, date: Date(), mediaItem: mediaItem!)
            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                let imagePath = "\(senderId!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = StorageMetadata()
                metadata.contentType = "image/type"
                storageReference.child(imagePath).putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                    if let error = error {
                        let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                        self?.present(alert, animated: true)
                        return
                    }
                    if let storageRef = self?.storageReference, let path = metadata?.path {
                        self?.saveImageMessage(imageUrl: storageRef.child(path).description, reference: newRef)
                    }
                }
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "Show Menu":
            if let destination = segue.destination.contents as? ChannelMenuTableViewController {
                destination.ownerOptions = channel?.ownerId == senderId
                destination.channel = channel
                destination.menuBarButton = menuBarButton
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        case "Show Quiz Session":
            if let destination = segue.destination.contents as? QuizSessionTableViewController {
                if let quiz = sender as? Quiz {
                    quiz.resetAnswers()
                    destination.quiz = quiz
                    destination.channelOwnerId = channel?.ownerId
                }
            }
        case "Show Quiz Results":
            if let destination = segue.destination.contents as? QuizResultsTableViewController {
                if let quiz = sender as? Quiz {
                    destination.quiz = quiz
                    destination.users = users
                }
            }
        default:
            break
        }
    }
    
    @IBAction func quizCreationDone(bySegue: UIStoryboardSegue) {
    }
    
    @objc private func fetchPreviousMessages(_ sender: Any) {
        queryLimit += 25
        if let handle = newMessagesHandle {
            messagesReference.removeObserver(withHandle: handle)
        }
        newMessagesHandle = observeNewMessages()
        refreshControl.endRefreshing()
    }
}

extension ChatViewController {
    private func isEarliest(message: JSQMessage, index: Int, timeUnit: Calendar.Component) -> Bool {
        let calendar = NSCalendar.current
        if index == 0 {
            return true
        } else if index > 0 {
            let previousMessage = messages[index - 1]
            return calendar.compare(message.date, to: previousMessage.date, toGranularity: timeUnit) == .orderedDescending && previousMessage.date < message.date
        }
        return false
    }
    
    private func getAvatarInitials(for senderName: String) -> String {
        let words = senderName.split(separator: " ", maxSplits: 2)
        switch words.count {
        case 2:
            return words.map( { $0.prefix(1) }).joined()
        default:
            return String(senderName.prefix(2))
        }
    }
    
    private func convertToMessageDateFormat(dateString: String) -> Date? {
        if let messageDate = dateString.convertToLongDate() {
            var timeInterval = DateComponents()
            timeInterval.day = 1
            return Calendar.current.date(byAdding: timeInterval, to: messageDate)
        }
        return nil
    }
    
    private func createLabel(_ rect: CGRect, text: String, font: UIFont, textColor: UIColor) -> UILabel {
        let label = UILabel(frame: rect)
        label.textAlignment = .center
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
    
    private func createFileMedia(fileUrl: URL, fileSize: String, senderId: String) -> FileMediaItem? {
        let stringUrl = fileUrl.absoluteString
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let label = self.createLabel(rect, text: stringUrl.pathExtension, font: UIFont.systemFont(ofSize: 14), textColor: UIColor.blue)
        let topView = UIView(frame: rect)
        topView.backgroundColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1)
        UIGraphicsBeginImageContext(rect.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            let fileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 85, height: 85))
            fileImageView.image = UIImage(named: "file_thumbnail")
            label.center = fileImageView.center
            fileImageView.addSubview(label)
            fileImageView.center = CGPoint(x: topView.center.x, y: topView.center.y - 10)
            
            let titleLabel = self.createLabel(rect, text: stringUrl.lastPathComponent, font: UIFont.systemFont(ofSize: 12), textColor: UIColor.black)
            titleLabel.center = CGPoint(x: topView.center.x, y: topView.center.y + 40)
            
            let sizeLabel = self.createLabel(rect, text: fileSize, font: UIFont.systemFont(ofSize: 12), textColor: UIColor.black)
            sizeLabel.center = CGPoint(x: titleLabel.center.x, y: titleLabel.center.y + 15)
            
            topView.addSubview(fileImageView)
            topView.addSubview(titleLabel)
            topView.addSubview(sizeLabel)
            topView.layer.render(in: currentContext)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            if let userId = self.senderId, let media = FileMediaItem(maskAsOutgoing: userId == senderId) {
                media.fileUrl = fileUrl
                media.image = image
                return media
            }
        }
        return nil
    }
    
    private func saveFileLocally(from url: URL, fileName: String) throws {
        let destinationDirectoryUrl = documentsDirectory.appendingPathComponent("AppPrototype")
        if !fileManager.fileExists(atPath: destinationDirectoryUrl.path) {
            try FileManager.default.createDirectory(at: destinationDirectoryUrl, withIntermediateDirectories: true)
        }
        let destinationUrl = destinationDirectoryUrl.appendingPathComponent(fileName)
        
        try FileManager.default.copyItem(at: url, to: destinationUrl)
    }
    
    private func getUniqueFileName(fileName name: String) -> String {

        func getUniqueName(fileName: String, counter: Int) -> String {
            for message in messages where message.media is FileMediaItem {
                let fileItem = message.media as! FileMediaItem
                if let stringUrl = fileItem.fileUrl?.absoluteString {
                    if stringUrl.lastPathComponent == fileName {
                        let nameNoExtention = name.deletingPathExtension
                        let extention = name.pathExtension
                        let nextCount = counter + 1
                        return getUniqueName(fileName: "\(nameNoExtention) (\(nextCount)).\(extention)", counter: nextCount)
                    }
                }
            }
            return fileName
        }

        return getUniqueName(fileName: name, counter: 0)
    }
    
    private func getFileSize(fileUrl url: URL) throws -> FileSize {
        let fileAttribute: [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: url.path)
        var fileSizeValue: UInt64 = 0
        let byteCountFormatter: ByteCountFormatter = ByteCountFormatter()
        if let fileNumberSize: NSNumber = fileAttribute[FileAttributeKey.size] as? NSNumber {
            fileSizeValue = UInt64(truncating: fileNumberSize)
            byteCountFormatter.countStyle = ByteCountFormatter.CountStyle.file
            if fileSizeValue < 50_000_000 {
                if fileSizeValue / 1000 > 0 {
                    byteCountFormatter.allowedUnits = fileSizeValue / 1000_000 > 0 ? .useMB : .useKB
                } else {
                    byteCountFormatter.allowedUnits = ByteCountFormatter.Units.useBytes
                }
            } else {
                return FileSize.overLimit
            }
        }
        return FileSize.some(byteCountFormatter.string(fromByteCount: Int64(fileSizeValue)))
    }
    
    enum FileSize {
        case some(String)
        case overLimit
    }
}

extension ChatViewController: UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("didPickDocumentAtUrl: \(url)")
        let downloadTask = URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
            if let error = error {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                self.present(alert, animated: true)
                return
            }
            do {
                if tempUrl != nil {
                    let stringUrl = url.absoluteString
                    let fileName = self.getUniqueFileName(fileName: stringUrl.lastPathComponent)
                    let fileSize = try self.getFileSize(fileUrl: tempUrl!)
                    switch fileSize {
                    case .some(let sizeString):
                        try self.saveFileLocally(from: tempUrl!, fileName: fileName)
                        
                        let newRef = self.messagesReference.childByAutoId()

                        let filePath = "\(self.senderId!)/\(fileName)"
                        let fileFirebasePath = "\(FirebaseReferences.storageUrl)/\(filePath)"
                        DispatchQueue.main.async {
                            if let fileFirebaseUrl = URL(string: fileFirebasePath), let mediaItem = self.createFileMedia(fileUrl: fileFirebaseUrl, fileSize: sizeString, senderId: self.senderId) {
                                self.userSentMediaByMessageId[newRef.key] = mediaItem
                                self.appendFileMessage(senderId: self.senderId, senderName: self.senderDisplayName, date: Date(), mediaItem: mediaItem)
                                
                                self.storageReference.child(filePath).putFile(from: url, metadata: nil) { metadata, error in
                                    if let error = error {
                                        let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                                        self.present(alert, animated: true)
                                        return
                                    }
                                    self.saveFileMessage(fileUrl: fileFirebasePath, fileSize: sizeString, reference: newRef)
                                }
                            }
                        }
                    case .overLimit:
                        let alert = Alerts.createSingleActionAlert(title: "File not Sent", message: "File exceeds maximum size limit - 50 MB.")
                        self.present(alert, animated: true)
                    }
                }
            } catch let error {
                let alert = Alerts.createSingleActionAlert(title: LocalizedStrings.AlertTitles.Error, message: error.localizedDescription)
                self.present(alert, animated: true)
                return
            }
        }
        downloadTask.resume()
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

class QuizMediaItem: JSQPhotoMediaItem {
    var quiz: Quiz?
    
    init(image: UIImage, quiz: Quiz?) {
        super.init(image: image)
        self.quiz = quiz
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
}

class FileMediaItem: JSQPhotoMediaItem {
    var fileUrl: URL?
    
    init(image: UIImage, fileUrl: URL) {
        super.init(image: image)
        self.fileUrl = fileUrl
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
}
