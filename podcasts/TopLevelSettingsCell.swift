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
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateImageScale()
            updateDisclosureScale()
        }
    }

    private func updateDisclosureScale() {
        let scale = ScaleFactorModifier.scaleFactor(for: traitCollection.preferredContentSizeCategory)
        disclosureImageView?.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    override func handleThemeDidChange() {
        settingsImage.tintColor = ThemeColor.primaryIcon01()
    }

    func updateImageScale() {
        let scale = ScaleFactorModifier.scaleFactor(for: traitCollection.preferredContentSizeCategory)
        settingsImage.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
