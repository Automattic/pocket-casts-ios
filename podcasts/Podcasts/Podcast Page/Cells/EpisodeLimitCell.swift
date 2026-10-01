import UIKit

class EpisodeLimitCell: ThemeableCell {
    @IBOutlet var limitMessage: UILabel!

    @IBOutlet var bottomDividerHeight: NSLayoutConstraint! {
        didSet {
            bottomDividerHeight.constant = 1.0 / traitCollection.displayScale
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        style = .primaryUi04

        registerForTraitChanges([UITraitDisplayScale.self]) { (view: EpisodeLimitCell, _) in
            view.bottomDividerHeight.constant = 1.0 / view.traitCollection.displayScale
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
