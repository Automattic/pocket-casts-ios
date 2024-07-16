import UIKit

class TranscriptGradientView: UIView {
    private var gradientLayer: CAGradientLayer!
    private var direction: Direction = .topToBottom

    enum Direction {
        case topToBottom, bottomToTop
    }

    init(direction: Direction) {
        super.init(frame: .zero)
        self.direction = direction
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    func setup() {
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            PlayerColorHelper.playerBackgroundColor01().cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        ]

        if direction == .bottomToTop {
            gradientLayer.colors = gradientLayer.colors?.reversed()
        }

        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = bounds
    }
}

