
import UIKit

class AccountActionCell: ThemeableCell {
    var imageAndTextColor: UIColor? = nil {
        didSet {
            handleThemeDidChange()
        }
    }

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
        guard let imageAndTextColor else {
            cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
            cellLabel.style = iconStyle
            return
        }


        cellImage.tintColor = imageAndTextColor
        cellLabel.textColor = imageAndTextColor
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

    override func prepareForReuse() {
        super.prepareForReuse()

        imageAndTextColor = nil
    }
}
