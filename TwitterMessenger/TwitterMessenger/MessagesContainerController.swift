
import UIKit

class MessagesContainerController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var input: UITextField!
    
    /*
     this part need refactoring
     comment by Jongwhan Lee
 */
    static var keyboardHeight:CGFloat = -1.0
    override func viewDidLoad() {
        super.viewDidLoad()
        input.delegate = self
        
        /*
         catch keyboard show, hide event
 */
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true;
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true;
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true;
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true;
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        addText()
        return true;
    }
    
    func addText() {
        print(input.text!)
        let t = input.text!
        let r = "OK, " + t
        MessagesViewController.sharedInstance?.addPost(text: t)
        MessagesViewController.sharedInstance?.addReply(text: r)
        let count =  MessagesViewController.sharedInstance?.messages.count
        MessagesViewController.sharedInstance?.tableView.scrollToRow(at: IndexPath(row: count!-1, section:0), at: .bottom, animated: true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        print(self.view.frame.origin.y)
        /*
         this section need to be enhanced.
         keyboard height varies sometimes in device
         comment by Jongwhan Lee
        */
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if MessagesContainerController.keyboardHeight < 0 {
                MessagesContainerController.keyboardHeight = keyboardSize.height
            }
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= MessagesContainerController.keyboardHeight
            }
            print("Y=", self.view.frame.origin.y)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        print(self.view.frame.origin.y)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if MessagesContainerController.keyboardHeight < 0 {
                MessagesContainerController.keyboardHeight = keyboardSize.height
            }
            
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += MessagesContainerController.keyboardHeight
            }
            print("Y=", self.view.frame.origin.y)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickPost(_ sender: Any) {
        addText()

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
