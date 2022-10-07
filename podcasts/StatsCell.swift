
import UIKit

class StatsCell: ThemeableCell {
    @IBOutlet var statsIcon: UIImageView!
    @IBOutlet var statName: UILabel!
    @IBOutlet var statValue: ThemeableLabel! {
        didSet {
            statValue.style = .primaryText02
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
}
