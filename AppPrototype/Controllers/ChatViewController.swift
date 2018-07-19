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

class ChatViewController: JSQMessagesViewController, URLSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    private let refreshControl = UIRefreshControl()
    private var queryLimit = 50
    
    let currentUser = Auth.auth().currentUser
    
    var channel: Channel?
    var users = [User]()
    var channelReference: DatabaseReference?
    
    private let sharedCache = URLCache.shared
    
    private lazy var messagesReference: DatabaseReference = channelReference!.child("messages")
    private var newMessagesHandle: DatabaseHandle?
    
    private var messages = [JSQMessage]()
    private var messagesFirebaseKeys: Set<String> = Set<String>()
    private var photoMediaItemsBySenderId = [String: JSQPhotoMediaItem]()
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
    private let placeholderImageURL = "placeholderImageURL"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyScrollsToMostRecentMessage = true
        senderId = Auth.auth().currentUser?.uid
        newMessagesHandle = observeNewMessages()
        tabBarController?.tabBar.isHidden = true
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchPreviousMessages(_:)), for: .valueChanged)
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
                        if let _ = self?.photoMediaItemsBySenderId[snapshot.key] {
                        } else if let newMediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self?.senderId) {
                            self?.appendImageMessage(senderId: id, senderName: senderName, date: messageDate, mediaItem: newMediaItem)
                            if imageURL.hasPrefix("gs://") {
                                let imageStorageRef = Storage.storage().reference(forURL: imageURL)
                                imageStorageRef.downloadURL { url, error in
                                    if url != nil {
                                        GeneralUtils.fetchImage(from: url!) { image, error in
                                            DispatchQueue.main.async {
                                                newMediaItem.image = image
                                                self?.collectionView.reloadData()
                                            }
                                        }
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
        if let message = JSQMessage(senderId: id, senderDisplayName: senderName, date: date, text: text) {
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
    
    private func saveImageMessage(at url: String, reference: DatabaseReference) {
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
            return NSAttributedString(string: message.date.longString)
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
                "text": text,
                "date": Date().longString
            ]
            
            newRef.setValue(messageValue)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            finishSendingMessage(animated: true)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let actionSheet = UIAlertController(title: "Send media", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                imagePicker.sourceType = .camera
            } else {
                imagePicker.sourceType = .photoLibrary
            }
            self?.present(imagePicker, animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self?.present(imagePicker, animated: true)
        }
        let documentPickerAction = UIAlertAction(title: "Send File", style: .default) { [weak self] action in
            let documentMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            documentMenu.delegate = self
            documentMenu.modalPresentationStyle = .formSheet
            self?.present(documentMenu, animated: true)
        }
        let fileAction = UIAlertAction(title: "Send File Mock", style: .default) { (action) in
            let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
            let label = self.createLabel(rect, text: "pdf", font: UIFont.systemFont(ofSize: 14), textColor: UIColor.blue)
            let topView = UIView(frame: rect)
            topView.backgroundColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1)
            UIGraphicsBeginImageContext(rect.size)
            if let currentContext = UIGraphicsGetCurrentContext() {
                let fileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 85, height: 85))
                fileImageView.image = UIImage(named: "file")
                label.center = fileImageView.center
                fileImageView.addSubview(label)
                fileImageView.center = CGPoint(x: topView.center.x, y: topView.center.y - 10)
                
                let titleLabel = self.createLabel(rect, text: "file.pdf", font: UIFont.systemFont(ofSize: 12), textColor: UIColor.black)
                titleLabel.center = CGPoint(x: topView.center.x, y: topView.center.y + 40)
                
                let sizeLabel = self.createLabel(rect, text: "32.0 KB", font: UIFont.systemFont(ofSize: 12), textColor: UIColor.black)
                sizeLabel.center = CGPoint(x: titleLabel.center.x, y: titleLabel.center.y + 15)
                
                topView.addSubview(fileImageView)
                topView.addSubview(titleLabel)
                topView.addSubview(sizeLabel)
                topView.layer.render(in: currentContext)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                
                let media = JSQPhotoMediaItem(image: image)
                self.appendImageMessage(senderId: self.senderId, senderName: self.senderDisplayName, date: Date(), mediaItem: media!)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
        actionSheet.addAction(documentPickerAction)
        actionSheet.addAction(fileAction)
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
        } else if let photoMedia = message.media as? JSQPhotoMediaItem, let image = photoMedia.image {
            let photoProvider = PhotoProvider(image: image)
            let photosViewController = photoProvider.photoViewer
            present(photosViewController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        print("didTapAvatarAt: \(indexPath.item)")
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
            photoMediaItemsBySenderId[newRef.key] = mediaItem
            appendImageMessage(senderId: senderId, senderName: senderDisplayName, date: Date(), mediaItem: mediaItem!)
            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                let imagePath = "\(senderId!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = StorageMetadata()
                metadata.contentType = "image/type"
                storageReference.child(imagePath).putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                    if let error = error {
                        let alert = Alerts.createSingleActionAlert(title: "Error", message: error.localizedDescription)
                        self?.present(alert, animated: true)
                        return
                    }
                    if let storageRef = self?.storageReference, let path = metadata?.path {
                        self?.saveImageMessage(at: storageRef.child(path).description, reference: newRef)
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
//        return messages.filter({ calendar.compare(message.date, to: $0.date, toGranularity: by) == .orderedSame })
//            .sorted(by: { $0.date < $1.date })
//            .first == message
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
}

extension ChatViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("didPickDocumentAtUrl: \(url)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
    }
}

class QuizMediaItem: JSQPhotoMediaItem {
    var quiz: Quiz?
    
    init(image: UIImage, quiz: Quiz?) {
        super.init(image: image)
        self.quiz = quiz
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
}
