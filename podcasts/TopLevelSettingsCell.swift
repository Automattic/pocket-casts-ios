import UIKit

class TopLevelSettingsCell: ThemeableCell {
    @IBOutlet var settingsImage: UIImageView!
    @IBOutlet var settingsLabel: UILabel! {
        didSet {
            settingsLabel.font = UIFont.font(ofSize: 15.0, scalingWith: .body)
        }
    }
    @IBOutlet var plusIndicator: UIImageView!

    var showsDisclosureIndicator = true {
        didSet {
            if showsDisclosureIndicator {
                accessoryView = TintableImageView(image: UIImage(named: "chevron"))
            } else {
                accessoryView = nil
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryView = TintableImageView(image: UIImage(named: "chevron"))
        settingsLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        updateColor()
    }

    override func handleThemeDidChange() {
        settingsImage.tintColor = ThemeColor.primaryIcon01()
    }

    func updateImageScale() {
        let category = UIApplication.shared.preferredContentSizeCategory
        let scale = ScaleFactorModifier.scaleFactor(for: category)

        settingsImage.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
