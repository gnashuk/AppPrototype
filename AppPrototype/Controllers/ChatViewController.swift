//
//  ChatViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 5/19/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import Photos
import Firebase
import JSQMessagesViewController
import NYTPhotoViewer

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

//    var image: UIImage?
    
    private let queue = DispatchQueue.global(qos: .background)
    private var userStoppedTypingWorkItem: DispatchWorkItem?
    
    private lazy var storageReference: StorageReference = Storage.storage().reference(forURL: "gs://appprototype-9cf29.appspot.com")
    private let placeholderImageURL = "placeholderImageURL"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyScrollsToMostRecentMessage = true
        senderId = Auth.auth().currentUser?.uid
        newMessagesHandle = observeNewMessages()
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(didPressBarButton))
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
                                        self?.fetchImage(from: url!) { image in
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
                            if let quizContent = snapshot.value as? [String: Any] {
                                if let title = quizContent["title"] as? String, let typeString = quizContent["type"] as? String, let timeLimitString = quizContent["timeLimit"] as? String {
                                if let questions = quizContent["questions"] as? [String: Any], let type = QuizType.create(rawValue: typeString), let timeLimit = TimeLimit.create(rawValue: timeLimitString) {
                                    let quiz = Quiz(title: title, type: type, timeLimit: timeLimit)
                                    for (_, value) in questions {
                                        if let questionContent = value as? [String: Any] , let answers = questionContent["answers"] as? [String: Any], let questionTitle = questionContent["title"] as? String {
                                            let question = QuizQuestion()
                                            question.title = questionTitle
                                            for (_, value) in answers {
                                                if let answerContent = value as? [String: Any], let text = answerContent["text"] as? String, let correct = answerContent["correct"] as? Bool {
                                                    let answer = QuizAnswer(text: text, correct: correct)
                                                    question.answers.append(answer)
                                                }
                                            }
                                            quiz.questions.append(question)
                                        }
                                    }
                                    self?.appendQuizMessage(senderId: id, senderName: senderName, date: messageDate, quiz: quiz)
                                    }}
                                
                            }
                        })
                    }
                    if let user = self?.users.filter({ $0.userId == id }).first, let keys = self?.userProfileImages.keys {
                        if !keys.contains(user) {
                            if let absolutePath = user.profileImageURL, let url = URL(string: absolutePath) {
                                self?.fetchImage(from: url) { image in
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
        if let image = GeneralUtils.createLabeledImage(width: 200, height: 200, text: quiz.title, fontSize: 14, labelBackgroundColor: .lightGray, labelTextColor: .white) {
            let mediaItem = QuizMediaItem(image: image, quiz: quiz)
            appendImageMessage(senderId: id, senderName: senderName, date: date, mediaItem: mediaItem)
        }
    }
    
    private func saveImageMessage(at url: String, reference: DatabaseReference) {
        let messageValue = [
            "senderId": senderId!,
            "imageURL": url,
            "senderName": senderDisplayName,
            "date": Date().customString
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
            return NSAttributedString(string: message.date.customString)
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
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
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
                "date": Date().customString
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
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
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
        print("didTapMessageBubbleAt: \(indexPath.item)")
        let message = messages[indexPath.item]
        if let quizMediaItem = message.media as? QuizMediaItem, let quiz = quizMediaItem.quiz {
            performSegue(withIdentifier: "Show Quiz Session", sender: quiz)
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
//            if let key = saveImageMessage() {
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
//                            self?.messagesReference.child(key).updateChildValues(["imageURL": path])
                        self?.saveImageMessage(at: storageRef.child(path).description, reference: newRef)
                    }
                }
            }
//            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Menu" {
            if let destination = segue.destination.contents as? ChannelMenuTableViewController {
                destination.ownerOptions = channel?.ownerId == senderId
                destination.channel = channel
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        } else if segue.identifier == "Show Quiz Session" {
            if let destination = segue.destination.contents as? QuizSessionTableViewController {
                if let quiz = sender as? Quiz {
                    destination.quiz = quiz
                }
            }
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

    @IBAction func appentTest(_ sender: UIBarButtonItem) {
        if let image = GeneralUtils.createLabeledImage(width: 200, height: 200, text: "Test #1\nTest #1\nTest #1", fontSize: 14, labelBackgroundColor: .lightGray, labelTextColor: .white) {
            let quiz = Quiz(title: "Test Title", type: .singleChoice, timeLimit: .minutes(1), numberOfQuestions: 0)
            for i in 0..<5 {
                let question = QuizQuestion()
                question.title = "Question\(i + 1)"
                for j in 0..<3 {
                    let answer = QuizAnswer(text: "Answer_\(i + 1).\(j + 1) AppPrototype[3094:36783] [App] if we're in the real pre-commit handler we can't actually add any new fences due to CA restriction", correct: false)
                    question.answers.append(answer)
                }
                quiz.questions.append(question)
            }
            let mediaItem = QuizMediaItem(image: image, quiz: quiz)
            appendImageMessage(senderId: "test", senderName: "test", date: Date(), mediaItem: mediaItem)
            scrollToBottom(animated: true)
        }
    }
}

extension ChatViewController {
    private func convertToMessageDateFormat(dateString: String) -> Date? {
        if let messageDate = dateString.convertToDate() {
            var timeInterval = DateComponents()
            timeInterval.day = 1
            return Calendar.current.date(byAdding: timeInterval, to: messageDate)
        }
        return nil
    }
    
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
    
    private func fetchImage(from url: URL, completion: @escaping (UIImage) -> ()) {
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
        if let response = sharedCache.cachedResponse(for: request) {
            if let image = UIImage(data: response.data) {
                completion(image)
            }
        } else {
            let session = URLSession(configuration: .cached)
            let dataTask = session.dataTask(with: request) { (data, response, error) in
                if let err = error {
                    print("Error occured: \(err)")
                } else {
                    if (response as? HTTPURLResponse) != nil {
                        if let imageData = data, let image = UIImage(data: imageData) {
                            completion(image)
                        } else {
                            print("Image file is corrupted")
                        }
                    } else {
                        print("No response from server")
                    }
                }
                if data != nil && response != nil {
                    let cachedResponse = CachedURLResponse(response: response!, data: data!)
                    self.sharedCache.storeCachedResponse(cachedResponse, for: request)
                }
            }
            dataTask.resume()
        }
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

