/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase
import JSQMessagesViewController
import FirebaseDatabase
class ChatViewController: JSQMessagesViewController {
  // MARK: Properties
  var messages = [JSQMessage]()
  var outgoingBubbleImageView: JSQMessagesBubbleImage!
  var incomingBubbleImageView: JSQMessagesBubbleImage!
  var messageRef: FIRDatabaseReference!
  var userIsTypingRef:FIRDatabaseReference!
  var usersTypingQuery: FIRDatabaseQuery!

  private var localTyping = false // 2
  var isTyping: Bool {
    get {
      return localTyping
    }
    set {
      // 3
      localTyping = newValue
      userIsTypingRef.setValue(newValue)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ChatChat"
    setupBubbles()

    // No avatars
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero

    messageRef=FIRDatabase.database().reference().child("messages");
  }

  private func setupBubbles() {
    let factory = JSQMessagesBubbleImageFactory()
    outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
      UIColor.jsq_messageBubbleBlueColor())
    incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
      UIColor.jsq_messageBubbleLightGrayColor())
  }

  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    observeMessages()
    observeTyping()
  }

  override func collectionView(collectionView: JSQMessagesCollectionView!,
                               messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
    return messages[indexPath.item]
  }

  override func collectionView(collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }

  override func collectionView(collectionView: JSQMessagesCollectionView!,
                               messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
    let message = messages[indexPath.item] // 1
    if message.senderId == senderId { // 2
      return outgoingBubbleImageView
    } else { // 3
      return incomingBubbleImageView
    }
  }

  override func collectionView(collectionView: UICollectionView,
                               cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
      as! JSQMessagesCollectionViewCell

    let message = messages[indexPath.item]

    if message.senderId == senderId {
      cell.textView!.textColor = UIColor.whiteColor()
    } else {
      cell.textView!.textColor = UIColor.blackColor()
    }
    
    return cell
  }

  override func collectionView(collectionView: JSQMessagesCollectionView!,
                               avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
    return nil
  }

  func addMessage(id: String, text: String) {
    let message = JSQMessage(senderId: id, displayName: "", text: text)
    messages.append(message)
  }

  override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,
                                   senderDisplayName: String!, date: NSDate!) {

    let itemRef = messageRef.childByAutoId() // 1
    let messageItem = [ // 2
      "text": text,
      "senderId": senderId
    ]
    itemRef.setValue(messageItem) // 3

    // 4
    JSQSystemSoundPlayer.jsq_playMessageSentSound()
    
    // 5
    finishSendingMessage()

    isTyping=false
  }

  private func observeMessages() {
    // 1
    let messagesQuery = messageRef.queryLimitedToLast(25)

    messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
      // 3
      let id = snapshot.value!["senderId"] as! String
      let text = snapshot.value!["text"] as! String

      // 4
      self.addMessage(id, text: text)

      // 5
      self.finishReceivingMessage()
    }

  }

  override func textViewDidChange(textView: UITextView) {
    super.textViewDidChange(textView)
    // If the text is not empty, the user is typing
    isTyping = textView.text != ""
  }

  private func observeTyping() {
    let typingIndicatorRef = FIRDatabase.database().reference().child("typingIndicator");
    userIsTypingRef = typingIndicatorRef.child(senderId);
    userIsTypingRef.onDisconnectRemoveValue()

    // 1
    usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)

    // 2
    usersTypingQuery.observeEventType(.Value) { (data: FIRDataSnapshot!) in

      // 3 You're the only typing, don't show the indicator
      if data.childrenCount == 1 && self.isTyping {
        return
      }

      // 4 Are there others typing?
      self.showTypingIndicator = data.childrenCount > 0
      self.scrollToBottomAnimated(true)
    }
  }


}