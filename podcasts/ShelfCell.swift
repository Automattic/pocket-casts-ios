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

    private let newBadge = NewBadgeLabel()

    /// Shows a "New" pill next to the action name.
    var showsNewBadge: Bool {
        get { !newBadge.isHidden }
        set {
            newBadge.isHidden = !newValue
            if newValue {
                newBadge.updateColors()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setHighlightedState(false)
        overrideUserInterfaceStyle = .dark
        setupNewBadge()
        updateSize()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ShelfCell, _) in
            view.updateSize()
        }
    }

    /// Moves the action name into a row of its own so the badge can sit beside it rather than below it.
    private func setupNewBadge() {
        guard let titleStack = actionName.superview as? UIStackView,
              let index = titleStack.arrangedSubviews.firstIndex(of: actionName) else { return }

        newBadge.isHidden = true

        let spacer = UIView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.setContentCompressionResistancePriority(.init(1), for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [actionName, newBadge, spacer])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8
        titleStack.insertArrangedSubview(titleRow, at: index)
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
        showsNewBadge = false
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(24, iconMetric.scaledValue(for: 24))
        actionIcon.updateSizeConstraints(to: iconSize)

        customViewContainer.updateSizeConstraints(to: iconSize)
    }
}

/// A pill that marks a row as a feature introduced in the current release.
private final class NewBadgeLabel: UILabel {
    private let insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    init() {
        super.init(frame: .zero)

        text = L10n.badgeNew
        font = .font(ofSize: 13, weight: .medium, scalingWith: .footnote)
        adjustsFontForContentSizeCategory = true
        textAlignment = .center
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateColors() {
        textColor = ThemeColor.playerContrast01()
        backgroundColor = ThemeColor.playerContrast05()
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }
}
