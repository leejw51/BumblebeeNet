

import UIKit
import SafariServices

class TweetsViewController: UITableViewController {

    var tweets : [JSON] = []
    let reuseIdentifier: String = "TweetCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Followers"
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TweetCell
        cell.load(text: "\(tweets[indexPath.row]["name"].string!), @\(tweets[indexPath.row]["screen_name"].string!)"
            ,   image:tweets[indexPath.row]["profile_image_url_https"].string!)        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard #available(iOS 9.0, *) else { return }
        let screenName = tweets[indexPath.row]["screen_name"].string!
        print(screenName)
        let m = MainViewController.sharedInstance!
        m.otherUser = screenName
        let viewController = storyboard?.instantiateViewController(withIdentifier: "MessageViewContainer") as! UIViewController
        navigationController?.pushViewController(viewController, animated: true)
      
    }
    
}

