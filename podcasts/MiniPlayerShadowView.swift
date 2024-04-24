import UIKit

class MiniPlayerShadowView: UIView {
    var shadowRadius: CGFloat = 15 {
        didSet {
            updateView()
        }
    }

    var shadowOffset = CGSize(width: 0, height: 8) {
        didSet {
            updateView()
        }
    }

    var shadowOpacity: Float = 1 {
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

        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
    }

    private func setup() {
        clipsToBounds = false

        updateView()
    }

    private func updateView() {
        if shadowOpacity == 0 { return }
        backgroundColor = .clear
        layer.cornerRadius = 12
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
}
