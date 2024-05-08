import UIKit

class MiniPlayerBackingView: UIView {
    var shadowRadius: CGFloat = 2 {
        didSet {
            updateView()
        }
    }

    var shadowOffset = CGSize(width: 0, height: -1) {
        didSet {
            updateView()
        }
    }

    var shadowOpacity: Float = 0.2 {
        didSet {
            updateView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }

    private func setup() {
        clipsToBounds = false

        updateView()
    }

    private func updateView() {
        if shadowOpacity == 0 { return }

        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowColor = UIColor(hex: "#1E1F1E").cgColor
    }
}
