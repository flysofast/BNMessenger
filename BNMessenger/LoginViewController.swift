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
import FirebaseAuth
import LocalAuthentication
class LoginViewController: UIViewController {

  var context = LAContext()

  @IBOutlet weak var btLogin: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func loginDidTouch(sender: AnyObject) {



    // 1.
    if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error:nil) {

      // 2.
      context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "Logging in with Touch ID",
                             reply: { (success : Bool, error : NSError? ) -> Void in

                              // 3.
                              dispatch_async(dispatch_get_main_queue(), {
                                if success {
                                  FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
                                    if error != nil { print(error!.description); return } // 2
                                    self.performSegueWithIdentifier("LoginToChat", sender: nil) // 3
                                    //    uZWSm5s9tre7KNJkZtkV0sHRALH3
                                  })
                                }

                                if error != nil {

                                  var message : NSString
                                  var showAlert : Bool

                                  // 4.
                                  switch(error!.code) {
                                  case LAError.AuthenticationFailed.rawValue:
                                    message = "There was a problem verifying your identity."
                                    showAlert = true
                                    break;
                                  case LAError.UserCancel.rawValue:
                                    message = "You pressed cancel."
                                    showAlert = true
                                    break;
                                  case LAError.UserFallback.rawValue:
                                    message = "You pressed password."
                                    showAlert = true
                                    break;
                                  default:
                                    showAlert = true
                                    message = "Touch ID may not be configured"
                                    break;
                                  }

                                  let alertView = UIAlertController(title: "Error",
                                    message: message as String, preferredStyle:.Alert)
                                  let okAction = UIAlertAction(title: "Darn!", style: .Default, handler: nil)
                                  alertView.addAction(okAction)
                                  if showAlert {
                                    self.presentViewController(alertView, animated: true, completion: nil)
                                  }
                                  
                                }
                              })
                              
      })
    } else {
      // 5.
      let alertView = UIAlertController(title: "Error",
                                        message: "Touch ID not available" as String, preferredStyle:.Alert)
      let okAction = UIAlertAction(title: "Darn!", style: .Default, handler: nil)
      alertView.addAction(okAction)
      FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
        if error != nil { print(error!.description); return } // 2
        self.performSegueWithIdentifier("LoginToChat", sender: nil) // 3
        //    uZWSm5s9tre7KNJkZtkV0sHRALH3
      })
      
    }


  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    super.prepareForSegue(segue, sender: sender)
    let navVc = segue.destinationViewController as! UINavigationController // 1
    let chatVc = navVc.viewControllers.first as! ChatViewController // 2
    chatVc.senderId = FIRAuth.auth()?.currentUser!.uid // 3
    chatVc.senderDisplayName = "" // 4
  }
  
}

