
import UIKit

class CreateSiriShortcutCell: ThemeableCell {
    @IBOutlet var buttonTitle: ThemeableLabel! {
        didSet {
            buttonTitle.style = .primaryIcon01
        }
    }
}
