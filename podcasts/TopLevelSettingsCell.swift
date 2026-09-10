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
    private var unreadIndicator: UIView?

    private let baseSettingsImageSize: CGFloat = 24
    private let baseDisclosureSize: CGFloat = 32
    private let baseUnreadIndicatorSize: CGFloat = 8

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

    /// Whether the row shows a dot for something new behind it, such as an unread What's New message.
    var showsUnreadIndicator = false {
        didSet {
            if showsUnreadIndicator, unreadIndicator == nil {
                setupUnreadIndicator()
            }
            unreadIndicator?.isHidden = !showsUnreadIndicator
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

    private func setupUnreadIndicator() {
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        indicator.backgroundColor = ThemeColor.support05()
        contentView.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: baseUnreadIndicatorSize),
            indicator.heightAnchor.constraint(equalToConstant: baseUnreadIndicatorSize),
            indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            indicator.leadingAnchor.constraint(greaterThanOrEqualTo: plusIndicator.trailingAnchor, constant: 8)
        ])

        unreadIndicator = indicator
        updateSize()
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let iconSize = max(baseSettingsImageSize, metric.scaledValue(for: baseSettingsImageSize))
        settingsImage.updateSizeConstraints(to: iconSize)

        plusIndicator.updateSizeConstraints(to: iconSize)

        let disclosureSize = max(baseDisclosureSize, metric.scaledValue(for: baseDisclosureSize))
        disclosureImageView?.frame.size = CGSize(width: disclosureSize, height: disclosureSize)

        let unreadIndicatorSize = max(baseUnreadIndicatorSize, UIFontMetrics(forTextStyle: .caption2).scaledValue(for: baseUnreadIndicatorSize))
        unreadIndicator?.updateSizeConstraints(to: unreadIndicatorSize)
        unreadIndicator?.layer.cornerRadius = unreadIndicatorSize / 2
    }

    override func handleThemeDidChange() {
        settingsImage.tintColor = ThemeColor.primaryIcon01()
        unreadIndicator?.backgroundColor = ThemeColor.support05()
    }
}
