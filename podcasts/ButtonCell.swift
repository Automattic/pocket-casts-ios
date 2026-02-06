
import UIKit

class ButtonCell: ThemeableCell {
    @IBOutlet var buttonTitle: UILabel! {
        didSet {
            buttonTitle.font = UIFont.font(ofSize: 17.0, scalingWith: .body)
        }
    }
}
