import UIKit

class MiniPlayerShadowView: UIView {

    enum Constants {
        static let shadowRadius = CGFloat(15)
        static let shadowOffset = CGSize(width: 0, height: -4)
        static let shadowOpacity = Float(1)
        static let shadowCornerRadius = CGFloat(12)
    }

    var shadowRadius: CGFloat = Constants.shadowRadius {
        didSet {
            updateView()
        }
    }

    var shadowOffset = Constants.shadowOffset {
        didSet {
            updateView()
        }
    }

    var shadowOpacity: Float = Constants.shadowOpacity {
        didSet {
            updateView()
        }
    }

    var shadowCornerRadius: CGFloat = Constants.shadowCornerRadius {
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

        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: shadowCornerRadius).cgPath
    }

    private func setup() {
        clipsToBounds = false

        updateView()
    }

    private func updateView() {
        if shadowOpacity == 0 { return }
        backgroundColor = .clear
        layer.cornerRadius = shadowCornerRadius
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}
