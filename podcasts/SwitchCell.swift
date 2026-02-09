import UIKit

class SwitchCell: ThemeableCell {
    let cellSwitch: ThemeableSwitch = {
        let cellSwitch = ThemeableSwitch()
        cellSwitch.isAccessibilityElement = false
        return cellSwitch
    }()
    @IBOutlet var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
            cellLabel.numberOfLines = 0
            cellLabel.adjustsFontForContentSizeCategory = true
            // Ensure label can expand vertically
            cellLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            cellLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        }
    }
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!

    var switchStyle: ThemeStyle = .primaryInteractive01

    var isLocked = true {
        didSet {
            cellSwitch.isUserInteractionEnabled = isLocked
            cellSwitch.isEnabled = isLocked
            contentView.alpha = isLocked ? 1 : 0.3
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryView = cellSwitch
        setNoImage()
    }

    override func handleThemeDidChange() {
        let color = AppTheme.colorForStyle(switchStyle)
        cellSwitch.onTintColor = color
        cellImage.tintColor = color
    }

    func setImage(imageName: String) {
        cellTextToImageConstraint.isActive = true
        cellImage.tintColor = cellSwitch.onTintColor
        cellImage.image = UIImage(named: imageName)
        updateSize()
    }

    func setNoImage() {
        cellTextToImageConstraint.isActive = false
        cellImage.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    override func accessibilityActivate() -> Bool {
        return isLocked
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let settingsSize = max(24, metric.scaledValue(for: 24))
        cellImage.updateSizeConstraints(to: settingsSize)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }
}
