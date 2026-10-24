
import UIKit

class StatsCell: ThemeableCell {
    @IBOutlet var statsIcon: UIImageView!
    @IBOutlet var statName: UILabel!
    @IBOutlet var statValue: ThemeableLabel! {
        didSet {
            statValue.style = .primaryText02
        }
    }

    @IBOutlet var nameBottomConstraint: NSLayoutConstraint!
    @IBOutlet var nameMaxWidthConstraint: NSLayoutConstraint!
    @IBOutlet var valueLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var valueTopConstraint: NSLayoutConstraint!

    private lazy var stackedConstraints = [
        statName.bottomAnchor.constraint(equalTo: statValue.topAnchor),
        statValue.leadingAnchor.constraint(equalTo: statName.leadingAnchor),
        statName.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor)
    ]

    private lazy var sideBySideValueAlignment = statValue.textAlignment

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSize()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: StatsCell, _) in
            view.updateSize()
        }
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

        let isStacked = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let sideBySideAlignment = sideBySideValueAlignment
        let sideBySideConstraints: [NSLayoutConstraint] = [nameBottomConstraint, nameMaxWidthConstraint, valueLeadingConstraint, valueTopConstraint]
        NSLayoutConstraint.deactivate(isStacked ? sideBySideConstraints : stackedConstraints)
        NSLayoutConstraint.activate(isStacked ? stackedConstraints : sideBySideConstraints)
        statValue.textAlignment = isStacked ? .natural : sideBySideAlignment
    }
}
