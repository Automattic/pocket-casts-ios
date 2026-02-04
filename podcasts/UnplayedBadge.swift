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

        clipsToBounds = true
        layer.cornerRadius = bounds.height / 2

        unplayedLabel = UILabel(frame: bounds)
        addSubview(unplayedLabel)
        unplayedLabel.anchorToAllSidesOf(view: self)
        unplayedLabel.font = UIFont.font(ofSize: 13, scalingWith: .footnote)
        unplayedLabel.adjustsFontForContentSizeCategory = true
        unplayedLabel.textAlignment = .center

        updateColors()
    }

    func updateColors() {
        backgroundColor = ThemeColor.primaryInteractive01()
        unplayedLabel.textColor = ThemeColor.primaryInteractive02()
    }
}
