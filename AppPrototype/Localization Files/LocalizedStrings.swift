//
//  LocalizedStrings.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 7/16/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import Foundation

struct LocalizedStrings {
    struct AlertTitles {
        static let Working = NSLocalizedString("Working", comment: "Application is working on logging user in.")
        static let EmptyLogin = NSLocalizedString("Empty Login Field", comment: "Empty login field while pressing login button.")
        static let AccountPasswordReset = NSLocalizedString("Account Password Reset", comment: "Password reset alert title.")
        static let Error = NSLocalizedString("Error", comment: "Error alert title.")
        static let MessageSent = NSLocalizedString("Message Sent", comment: "Password reset email sent alert title.")
        static let LoginFailed = NSLocalizedString("Login Failed", comment: "Login failed alert title.")
        static let LogoutFailed = NSLocalizedString("Logout Failed", comment: "Facebook logout failed alert title.")
        static let SendMedia = NSLocalizedString("Send Media", comment: "Send media message.")
        static let DuplicateTitle = NSLocalizedString("Duplicate Title", comment: "Repeating title.")
        static let InsufficientQuestionCount = NSLocalizedString("Insufficient Question Count", comment: "Wrong number of questions.")
        static let SaveProgress = NSLocalizedString("Save Progress", comment: "Save progress of what user was performing.")
        static let FinishCreation = NSLocalizedString("Finish Creation", comment: "Finish creating something.")
        static let MissingTitles = NSLocalizedString("Missing Titles", comment: "One or more titles are not provided.")
        static let DuplicateQuestions = NSLocalizedString("Duplicate Questions", comment: "Repeating question titles.")
        static let MissingAnswers = NSLocalizedString("Missing Answers", comment: "One or more answers are not provided.")
        static let MissingCorrertAnswers = NSLocalizedString("Missing Corrert Answers", comment: "No answer is selected as correct.")
        static let ConfirmSubscription = NSLocalizedString("Confirm Subscription", comment: "Accept subscription.")
        static let NonUniqueChannelTitle = NSLocalizedString("Non-unique Channel Title", comment: "Repeating channel title.")
        static let EmptyChannelTitle = NSLocalizedString("Empty Channel Title", comment: "Channel title field not provided.")
        static let BeginQuiz = NSLocalizedString("Begin Quiz", comment: "Start quiz session.")
        static let ClearAll = NSLocalizedString("Clear All", comment: "Remove everything.")
        static let FinishQuiz = NSLocalizedString("Finish Quiz", comment: "Finish quiz session.")
        static let RemoveProfileImage = NSLocalizedString("Remove Profile Image", comment: "Delete user profile image.")
        static let ErrorOccured = NSLocalizedString("Error Occured", comment: "Error happened.")
        static let ChangeSaved = NSLocalizedString("Change Saved", comment: "Change written to storage.")
        static let EmptyNameField = NSLocalizedString("Empty Name Field", comment: "Empty name field.")
        static let LogOutError = NSLocalizedString("Log Out Error", comment: "Error on logging out.")
        static let DuplicateAnswer = NSLocalizedString("Duplicate Answer", comment: "Repeating answer text.")
        static let QuizOver = NSLocalizedString("Quiz Over", comment: "Quiz was finished.")
        static let DownloadFile = NSLocalizedString("Download File", comment: "Download remote file")
        static let AccountDeletion = NSLocalizedString("Account Deletion", comment: "Removal of user account.")
        static let ConfirmRemoval = NSLocalizedString("Confirm Removal", comment: "Approve removal.")
        static let ConfirmChange = NSLocalizedString("Confirm Change", comment: "Approve change.")
    }
    
    struct AlertMessages {
        static let PleaseWait = NSLocalizedString("Please wait...", comment: "Please wait while user is logged in.")
        static let EmptyLogin = NSLocalizedString("Email and password fields can't be empty.", comment: "Email and password fields can't be empty.")
        static let EnterEmail = NSLocalizedString("Enter the email associated with account.", comment: "Enter the email associated with account.")
        static let MessageSent = NSLocalizedString("Password reset link was sent to the specified email.", comment: "Password reset link was sent to the specified email.")
        static let DuplicateTitle = NSLocalizedString("Quiz with selected title already exists in user's repository.", comment: "Quiz with selected title already exists in user's repository.")
        static let InsufficientQuestionCount = NSLocalizedString("To create a quiz add at least one question.", comment: "To create a quiz add at least one question.")
        static let SaveProgress = NSLocalizedString("Do you want to keep the draft?", comment: "Question if user wants to keep a draft.")
        static let ChooseAction = NSLocalizedString("Choose the action.", comment: "Choose the action.")
        static let MissingTitles = NSLocalizedString("Please provide all question titles.", comment: "Please provide all question titles.")
        static let DuplicateQuestions = NSLocalizedString("Quiz contains duplicated question titles.", comment: "Quiz contains duplicated question titles.")
        static let MissingAnswers = NSLocalizedString("Some questions don't have any answers.", comment: "Some questions don't have any answers.")
        static let MissingCorrectAnswers = NSLocalizedString("Some questions don't have any answers marked as correct.", comment: "Some questions don't have any answers marked as correct.")
        static let ConfirmSubscription = NSLocalizedString("Do you want to join the channel %@?", comment: "Do you want to join the channel?")
        static let NonUniqueChannelTitle = NSLocalizedString("Channel with such title already exists.", comment: "Channel with such title already exists.")
        static let EmptyChannelTitle = NSLocalizedString("Please provide a channel title.", comment: "Please provide a channel title.")
        static let BeginQuiz = NSLocalizedString("Do you want to start quiz %@ now?", comment: "Do you want to start quiz now?")
        static let ClearAll = NSLocalizedString("Are you sure you want to delete all notifications?", comment: "Are you sure you want to delete all notifications?")
        static let FinishQuiz = NSLocalizedString("Are you sure you want to complete the quiz?", comment: "Are you sure you want to complete the quiz?")
        static let RemoveProfileImage = NSLocalizedString("Profile image was succesfully deleted.", comment: "Profile image was succesfully deleted.")
        static let NameChangeSaved = NSLocalizedString("User display name was successfuly changed to %@.", comment: "User display name was successfuly changed to a new one.")
        static let ImageChangeSaved = NSLocalizedString("User profile image was successfuly changed.", comment: "User profile image was successfuly changed.")
        static let EmptyNameField = NSLocalizedString("User name field can't be empty.", comment: "User name field can't be empty.")
        static let DuplicateAnswer = NSLocalizedString("The answer repeats an existing.", comment: "The answer repeats an existing.")
        static let QuizOver = NSLocalizedString("Time is up. Your current progress will be submitted automatically.", comment: "Time is up. Your current progress will be submitted automatically.")
        static let DownloadFile = NSLocalizedString("Do you want to download file %@?", comment: "Do you want to download file?")
        static let AccountDeletion = NSLocalizedString("Do you want to delete this user account?", comment: "Do you want to delete this user account?")
        static let ConfirmRemoval = NSLocalizedString("Are you sure you want to permanently remove user account?", comment: "Are you sure you want to permanently remove user account?")
        static let ConfirmChange = NSLocalizedString("Are you sure you want to save changes?", comment: "Are you sure you want to save changes?")
    }
    
    struct AlertActions {
        static let Ok = NSLocalizedString("OK", comment: "OK - confirmation.")
        static let Hide = NSLocalizedString("Hide", comment: "Hide locading alert.")
        static let SendFile = NSLocalizedString("Send File", comment: "Send file in message.")
        static let Cancel = NSLocalizedString("Cancel", comment: "Cancel alert.")
        static let Keep = NSLocalizedString("Keep", comment: "Keep; leave unchanged.")
        static let Discard = NSLocalizedString("Discard", comment: "Delete draft; abandon.")
        static let Save = NSLocalizedString("Save", comment: "Write to storage.")
        static let SaveAndPost = NSLocalizedString("Save and Post", comment: "Write to storage and then make public/available.")
        static let Confirm = NSLocalizedString("Confirm", comment: "Confirm; accept.")
        static let Camera = NSLocalizedString("Camera", comment: "Photo camera.")
        static let PhotoLibrary = NSLocalizedString("Photo Library", comment: "Image gallery.")
        static let ViewImage = NSLocalizedString("View Image", comment: "Display image.")
        static let RemoveImage = NSLocalizedString("Remove Image", comment: "Delete image.")
    }
    
    struct NavigationBarItemTitles {
        static let Back = NSLocalizedString("Back", comment: "Back; return")
        static let NotificationSettings = NSLocalizedString("Notifications", comment: "Settings for notifications on current device.")
        static let Channels = NSLocalizedString("Channels", comment: "User owned channels in settings.")
        static let Quizes = NSLocalizedString("Quizes", comment: "User created quizes in settings.")
        static let Join = NSLocalizedString("Join", comment: "Join navigation bar button title.")
    }
    
    struct TabBarItemTitles {
        static let Chats = NSLocalizedString("Chats", comment: "Chats tab bar item title.")
        static let Alerts = NSLocalizedString("Alerts", comment: "Alerts tab bar item title.")
        static let Settings = NSLocalizedString("Settings", comment: "Settings tab bar item title.")
    }
    
    struct LabelTexts {
        static let ManageChannels = NSLocalizedString("Manage Channel", comment: "Edit channel settings.")
        static let CreateQuiz = NSLocalizedString("Create Quiz", comment: "Create a new quiz for a channel.")
        static let ShowChannelInfo = NSLocalizedString("Show Channel Info", comment: "Display information about current channel to user.")
        static let QuestionCount = NSLocalizedString("Question Count: %d", comment: "Amount of questions.")
        static let QuestionNumber = NSLocalizedString("Question #%d", comment: "Number of a question.")
        static let Channelinvitation = NSLocalizedString("Channel Invitation", comment: "Invitation to join a channel.")
        static let QuizAvailable = NSLocalizedString("Quiz Available", comment: "Notification about a quiz addition in a channel.")
        static let ResponsesCount = NSLocalizedString("Responses count: %d", comment: "Number of responses.")
    }
    
    struct PickerViewDataItems {
        static let Minute = NSLocalizedString("1 minute", comment: "Single minute.")
        static let Minutes = NSLocalizedString("%d minutes", comment: "Multiple minutes.")
        static let None = NSLocalizedString("none", comment: "Nothing; lack of anything")
    }
    
    struct TableViewRowActions {
        static let Edit = NSLocalizedString("Edit", comment: "Edit; modify.")
        static let Delete = NSLocalizedString("Delete", comment: "Delete; remove.")
    }
    
    struct SearchBarText {
        static let SearchChannels = NSLocalizedString("Search Channels", comment: "Search for a channel in search bar.")
    }
    
    struct TextViewText {
        static let Desciption = NSLocalizedString("Description (Optional)", comment: "Description placeholder.")
        static let Title = NSLocalizedString("Title", comment: "Title.")
        static let AnswerText = NSLocalizedString("Answer Text", comment: "Text of an answer.")
    }
    
    struct TableViewHeaderTitle {
        static let SelectedUsers = NSLocalizedString("Selected Users", comment: "Selected users section.")
        static let AllUsers = NSLocalizedString("All Users", comment: "All remaining users section.")
    }
    
    struct AttributedStrings {
        static let ChannelInvitation = NSLocalizedString(" has invited you to join channel ", comment: "user received channel invitation.")
        static let Quiz = NSLocalizedString("Quiz ", comment: "Test.")
        static let WasAddedIn = NSLocalizedString(" was added in ", comment: "Something was added in.")
    }
}
