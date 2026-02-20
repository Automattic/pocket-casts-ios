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
            actionName.font = .font(ofSize: 14, weight: .regular, scalingWith: .subheadline)
        }
    }

    @IBOutlet var actionIcon: UIImageView!
    @IBOutlet var customViewContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        setHighlightedState(false)
        overrideUserInterfaceStyle = .dark
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
}
