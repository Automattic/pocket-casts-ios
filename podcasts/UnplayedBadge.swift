import UIKit

class UnplayedBadge: UIView {
    var unplayedCount = 0 {
        didSet {
            unplayedLabel.text = "\(unplayedCount)"
        }
    }

    var showsNumber = true {
        didSet {
            unplayedLabel.isHidden = !showsNumber
            layer.cornerRadius = bounds.height / 2
        }
    }

    private var unplayedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = AppTheme.appTintColor()
        clipsToBounds = true
        layer.cornerRadius = bounds.height / 2

        unplayedLabel = UILabel(frame: bounds)
        addSubview(unplayedLabel)
        unplayedLabel.anchorToAllSidesOf(view: self)
        unplayedLabel.font = UIFont.systemFont(ofSize: 13)
        unplayedLabel.textColor = UIColor.white
        unplayedLabel.textAlignment = .center
    }
}
