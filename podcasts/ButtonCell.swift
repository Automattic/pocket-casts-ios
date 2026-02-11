
import UIKit

class ButtonCell: ThemeableCell {
    @IBOutlet var buttonTitle: UILabel! {
        didSet {
            buttonTitle.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
        }
    }
}
