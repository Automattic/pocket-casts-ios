import UIKit

class TopLevelSettingsCell: ThemeableCell {
    @IBOutlet var settingsImage: UIImageView!
    @IBOutlet var settingsLabel: UILabel! {
        didSet {
            settingsLabel.font = UIFont.font(ofSize: 15.0, scalingWith: .body)
        }
    }
    @IBOutlet var plusIndicator: UIImageView!

    private var disclosureImageView: TintableImageView?

    var showsDisclosureIndicator = true {
        didSet {
            if showsDisclosureIndicator {
                let imageView = TintableImageView(image: UIImage(named: "chevron"))
                disclosureImageView = imageView
                accessoryView = imageView
                updateDisclosureScale()
            } else {
                disclosureImageView = nil
                accessoryView = nil
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let imageView = TintableImageView(image: UIImage(named: "chevron"))
        disclosureImageView = imageView
        accessoryView = imageView
        settingsLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        updateColor()
        updateDisclosureScale()

        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    @objc private func contentSizeCategoryDidChange() {
        updateImageScale()
        updateDisclosureScale()
    }

    private func updateDisclosureScale() {
        let category = UIApplication.shared.preferredContentSizeCategory
        let scale = ScaleFactorModifier.scaleFactor(for: category)
        disclosureImageView?.transform = CGAffineTransform(scaleX: scale, y: scale)
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
