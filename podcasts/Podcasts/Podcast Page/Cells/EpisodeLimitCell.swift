import UIKit

class EpisodeLimitCell: ThemeableCell {
    @IBOutlet var limitMessage: UILabel!

    @IBOutlet var bottomDividerHeight: NSLayoutConstraint! {
        didSet {
            bottomDividerHeight.constant = 1.0 / UIScreen.main.scale
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        style = .primaryUi04
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
