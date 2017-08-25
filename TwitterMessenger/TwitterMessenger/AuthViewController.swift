
import UIKit
import Accounts
import Social
import SafariServices

class AuthViewController: UIViewController, SFSafariViewControllerDelegate {
    
    var swifter: Swifter

    // Default to using the iOS account framework for handling twitter auth
    let useACAccount = false

    func test() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let p = documentsPath + "/talk.json"
        print("Path=", p)
        var a = TalkDatabase()
        a.makeTest()
        a.save(filename: p)
        a.load(filename: p)

    }
    required init?(coder aDecoder: NSCoder) {
        
        self.swifter = Swifter(consumerKey: "2bEWiOVdCvDqKmXDHYPILZn6W", consumerSecret: "6qycIj9O51GFo1H3WwJh9hPRgWeaOrrGcrkvmwgBd6irNZgD11")
        super.init(coder: aDecoder)
    }

    @IBAction func didTouchUpInsideLoginButton(_ sender: AnyObject) {
     
        let failureHandler: (Error) -> Void = { error in
            self.alert(title: "Error", message: error.localizedDescription)
            
        }

        if useACAccount {
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)

            // Prompt the user for permission to their twitter account stored in the phone's settings
            accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
                guard granted else {
                    self.alert(title: "Error", message: error!.localizedDescription)
                    return
                }
                
                let twitterAccounts = accountStore.accounts(with: accountType)!
                
                if twitterAccounts.isEmpty {
                    self.alert(title: "Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                } else {
                    let twitterAccount = twitterAccounts[0] as! ACAccount
                    self.swifter = Swifter(account: twitterAccount)
                    self.fetchTwitterHomeStream()
                }
            }
        } else {
            let url = URL(string: "swifter://success")!
       
            swifter.authorize(with: url, presentFrom: self, success: { _ in
                    self.fetchTwitterHomeStream()
                }, failure: failureHandler)
        }
    }

    func fetchTwitterHomeStream() {
        let failureHandler: (Error) -> Void = { error in
            self.alert(title: "Error", message: error.localizedDescription)
        }
        
        let utag = UserTag.screenName("")       
        self.swifter.getUserFollowers(for:utag , success: { json in
            // Successfully fetched timeline, so lets create and push the table view
            
            let tweetsViewController = self.storyboard!.instantiateViewController(withIdentifier: "TweetsViewController") as! TweetsViewController
            guard let tweets = json.0.array else { return }
            tweetsViewController.tweets = tweets
            self.navigationController?.pushViewController(tweetsViewController, animated: true)
            
        }, failure: failureHandler)
        
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }


}
