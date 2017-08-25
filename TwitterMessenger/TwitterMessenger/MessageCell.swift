//
//  MessageCell.swift
//  Swifter
//
//  Created by Jongwhan Lee on 25/07/2017.


import UIKit

class MessageCell: UITableViewCell {

    var isRight = true
    @IBOutlet weak var rightPic: UIImageView!
    @IBOutlet weak var rightSay: UILabel!
    @IBOutlet weak var leftPic: UIImageView!
    @IBOutlet weak var leftSay: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    func refresh() {
        if (self.isRight) {
            let image = UIImage(named:"right_bubble.png" )
            let image2 = image?.stretchableImage(withLeftCapWidth: 19, topCapHeight: 14)
            rightPic.image = image2
            rightPic.isHidden = false
            rightSay.isHidden = false
            leftPic.isHidden = true
            leftSay.isHidden = true
        }
        else {
            let image = UIImage(named:"left_bubble.png" )
            let image2 = image?.stretchableImage(withLeftCapWidth: 23, topCapHeight: 14)
            leftPic.image = image2
            rightPic.isHidden = true
            rightSay.isHidden = true
            leftPic.isHidden = false
            leftSay.isHidden = false
        }
    }
}
