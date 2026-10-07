import UIKit

class UnplayedBadge: UIView {
    var unplayedCount = 0 {
        didSet {
            unplayedLabel.text = Self.text(forCount: unplayedCount)
        }
    }

    static func text(forCount count: Int) -> String {
        count > 99 ? "99+" : "\(count)"
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
        unplayedLabel.anchorToAllSidesOf(view: self, padding: 4)
        unplayedLabel.font = UIFont.font(ofSize: 13, scalingWith: .footnote)
        unplayedLabel.adjustsFontForContentSizeCategory = true
        unplayedLabel.adjustsFontSizeToFitWidth = true
        unplayedLabel.minimumScaleFactor = 0.7
        unplayedLabel.textAlignment = .center

        updateColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func updateColors() {
        backgroundColor = ThemeColor.primaryInteractive01()
        unplayedLabel.textColor = ThemeColor.primaryInteractive02()
    }
}
