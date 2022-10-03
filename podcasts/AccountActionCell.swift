
import UIKit

class AccountActionCell: ThemeableCell {
    @IBOutlet var cellLabel: ThemeableLabel! {
        didSet {
            cellLabel.style = iconStyle
        }
    }

    @IBOutlet var cellImage: UIImageView! {
        didSet {
            cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
        }
    }

    override var iconStyle: ThemeStyle {
        didSet {
            handleThemeDidChange()
        }
    }

    @IBOutlet var counterLabel: ThemeableLabel! {
        didSet {
            counterLabel.style = .primaryInteractive02
        }
    }

    @IBOutlet var counterView: ThemeableView! {
        didSet {
            counterView.style = .primaryIcon01
            counterView.layer.cornerRadius = 16
        }
    }

    override func handleThemeDidChange() {
        cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
        cellLabel.style = iconStyle
    }

    var showsDisclosureIndicator = false {
        didSet {
            if showsDisclosureIndicator {
                accessoryView = TintableImageView(image: UIImage(named: "chevron"))
                updateColor()
            } else {
                accessoryView = nil
            }
        }
    }
}
