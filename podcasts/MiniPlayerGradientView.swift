import UIKit

class MiniPlayerGradientView: UIView {

    var colors: [UIColor] = [.black, .white] {
        didSet {
            updateView()
        }
    }
    private var gradientLayer: CAGradientLayer = CAGradientLayer()

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
        gradientLayer.frame = bounds
    }

    private func setup() {
        backgroundColor = .clear
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
    }

    func updateView() {
        gradientLayer.colors = colors.map({ $0.cgColor })
        setNeedsDisplay()
    }
}
