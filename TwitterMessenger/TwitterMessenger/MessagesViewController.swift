

import UIKit

class MessageDatum {
    var isRight = true
    var text = ""
}
class MessagesViewController: UITableViewController {
    var messages : [MessageDatum] = []
    static var sharedInstance: MessagesViewController?
    var otherUser = ""
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        MessagesViewController.sharedInstance = self
        
        self.otherUser = MainViewController.sharedInstance!.otherUser
        print("OtherUser=", self.otherUser)
        
        initialize()
    }
    
    func initialize() {
        let data:[ [String:String] ]? = TalkDatabase.sharedInstance!.table[otherUser] as! [ [String:String] ]?
        if nil != data {
            for m in data! {
                if "true" == m["Right"] {
                    doAddPost(text:m["Say"]!)
                }
                else {
                    doAddReply(text:m["Say"]!)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        // Configure the cell...
        let row = indexPath.row
        let thisone = self.messages[row]
        cell.rightSay?.text = thisone.text
        cell.leftSay?.text = thisone.text
        cell.isRight = thisone.isRight
        cell.refresh()

        return cell
    }
    
    func doAddPost(text:String) {
        let newone = MessageDatum()
        newone.isRight = true
        newone.text = text;
        messages.append(newone)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: messages.count-1, section: 0)], with: .automatic)
        tableView.endUpdates()
        
    }
    func addPost(text:String) {
        doAddPost(text: text)
        TalkDatabase.sharedInstance?.addPost(user: self.otherUser, text: text)
    }
    
    func doAddReply(text:String) {
        let newone = MessageDatum()
        newone.isRight = false
        newone.text = text;
        messages.append(newone)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: messages.count-1, section: 0)], with: .automatic)
        tableView.endUpdates()
        
    }
    func addReply(text:String) {
        doAddReply(text:text)
         TalkDatabase.sharedInstance?.addReply(user: self.otherUser, text: text)
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
