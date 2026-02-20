import UIKit

class ShelfCell: UITableViewCell {
    @IBOutlet var actionName: ThemeableLabel! {
        didSet {
            actionName.style = .playerContrast01
            actionName.font = .font(ofSize: 18, weight: .medium, scalingWith: .headline)
        }
    }

    @IBOutlet var actionSubtitle: ThemeableLabel! {
        didSet {
            actionSubtitle.style = .playerContrast02
            actionSubtitle.font = .font(ofSize: 14, weight: .regular, scalingWith: .subheadline)
        }
    }

    @IBOutlet var actionIcon: UIImageView!
    @IBOutlet var customViewContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        setHighlightedState(false)
        overrideUserInterfaceStyle = .dark
        updateSize()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlightedState(selected)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlightedState(highlighted)
    }

    private func setHighlightedState(_ highlighted: Bool) {
        if highlighted {
            let highlightColor = PlayerColorHelper.playerHighlightColor07(for: .dark)
            backgroundColor = highlightColor
            contentView.backgroundColor = highlightColor
        } else {
            backgroundColor = UIColor.clear
            contentView.backgroundColor = UIColor.clear
        }
    }

    private func updateBgColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
        accessoryView?.backgroundColor = color
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        customViewContainer.removeAllSubviews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(24, iconMetric.scaledValue(for: 24))
        actionIcon.updateSizeConstraints(to: iconSize)
    }
}
