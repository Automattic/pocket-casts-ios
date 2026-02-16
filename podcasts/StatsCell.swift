
import UIKit

class StatsCell: ThemeableCell {
    @IBOutlet var statsIcon: UIImageView!
    @IBOutlet var statName: UILabel!
    @IBOutlet var statValue: ThemeableLabel! {
        didSet {
            statValue.style = .primaryText02
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSize()
    }

    @IBOutlet var leadingSpaceToIcon: NSLayoutConstraint!

    func hideIcon() {
        statsIcon.isHidden = true
        leadingSpaceToIcon.constant = -28
    }

    func showIcon() {
        statsIcon.isHidden = false
        leadingSpaceToIcon.constant = 10
    }

    override func handleThemeDidChange() {
        statsIcon.tintColor = ThemeColor.primaryIcon01()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}


    // MARK: - Dynamic type

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let size = max(metric.scaledValue(for: 24), 24)
        statsIcon.updateSizeConstraints(to: size)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }
}
