#if !os(watchOS)
import UIKit

public class GradientView: UIView {
    private var gradientLayer: CAGradientLayer!
    private var firstColor: UIColor!
    private var secondColor: UIColor!

    public init(firstColor: UIColor, secondColor: UIColor) {
        super.init(frame: .zero)
        self.firstColor = firstColor
        self.secondColor = secondColor
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

    public func updateColors(firstColor: UIColor, secondColor: UIColor) {
        self.firstColor = firstColor
        self.secondColor = secondColor

        gradientLayer.colors = [
            firstColor.cgColor,
            secondColor.cgColor
        ]
    }

    func setup() {
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            firstColor.cgColor,
            secondColor.cgColor
        ]

        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = bounds
    }
}
#endif
