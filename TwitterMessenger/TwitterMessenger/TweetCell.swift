
import UIKit

class TweetCell: UITableViewCell {
    @IBOutlet weak var information: UILabel!
    @IBOutlet weak var pic: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func load(text:String,  image: String) {
        self.information?.text = text
        self.pic.imageFromUrl (urlString:  image)
    }
}
