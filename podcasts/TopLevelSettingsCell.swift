import UIKit

class TopLevelSettingsCell: ThemeableCell {
    @IBOutlet var settingsImage: UIImageView!
    @IBOutlet var settingsLabel: UILabel! {
        didSet {
            settingsLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
            settingsLabel.adjustsFontForContentSizeCategory = true
        }
    }
    @IBOutlet var plusIndicator: UIImageView!

    private var disclosureImageView: TintableImageView?

    private let baseSettingsImageSize: CGFloat = 24
    private let baseDisclosureSize: CGFloat = 32

    var showsDisclosureIndicator = true {
        didSet {
            if showsDisclosureIndicator {
                setupDisclosureImageView()
            } else {
                disclosureImageView = nil
                accessoryView = nil
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: TopLevelSettingsCell, _) in
            view.updateSize()
        }

        setupDisclosureImageView()
        settingsLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        updateColor()
        updateSize()
    }

    private func setupDisclosureImageView() {
        let imageView = TintableImageView(image: UIImage(named: "chevron"))
        disclosureImageView = imageView

        let metric = UIFontMetrics(forTextStyle: .body)
        let size = max(baseDisclosureSize, metric.scaledValue(for: baseDisclosureSize))
        imageView.frame = CGRect(x: 0, y: 0, width: size, height: size)

        accessoryView = imageView
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let iconSize = max(baseSettingsImageSize, metric.scaledValue(for: baseSettingsImageSize))
        settingsImage.updateSizeConstraints(to: iconSize)

        plusIndicator.updateSizeConstraints(to: iconSize)

        let disclosureSize = max(baseDisclosureSize, metric.scaledValue(for: baseDisclosureSize))
        disclosureImageView?.frame.size = CGSize(width: disclosureSize, height: disclosureSize)
    }

    override func handleThemeDidChange() {
        settingsImage.tintColor = ThemeColor.primaryIcon01()
    }
}
