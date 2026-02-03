
import UIKit

class CreateSiriShortcutCell: ThemeableCell {
    @IBOutlet var buttonTitle: ThemeableLabel! {
        didSet {
            buttonTitle.style = .primaryIcon01
            buttonTitle.font = UIFont.font(ofSize: 17.0, scalingWith: .body)
        }
    }
}
