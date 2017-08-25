

import Foundation
import UIKit

// in production stage
// images will be processed asynchronous way
// comment by jongwhan lee
extension UIImageView {
    public func imageFromUrl(urlString: String) {
        let url = URL(string: urlString)
        let data = try? Data(contentsOf: url!)
        if (data != nil) {
        self.image = UIImage(data: data!)
        }
    }
}
