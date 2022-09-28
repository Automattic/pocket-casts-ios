import UIKit

class TopLevelSettingsCell: ThemeableCell {
    @IBOutlet var settingsImage: UIImageView!
    @IBOutlet var settingsLabel: UILabel!
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
        updateColor()
    }

    override func handleThemeDidChange() {
        settingsImage.tintColor = ThemeColor.primaryIcon01()
    }
}
