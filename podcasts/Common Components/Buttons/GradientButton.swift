import UIKit

class GradientButton: UIButton {
    private var gradientLayer: CAGradientLayer?

    var gradientStartStyle: ThemeStyle = .gradient01A
    var gradientEndStyle: ThemeStyle = .gradient01E

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        setupGradient()
        handleThemeChanged()
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChanged), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func handleThemeChanged() {
        gradientLayer?.colors = [AppTheme.colorForStyle(gradientStartStyle).cgColor, AppTheme.colorForStyle(gradientEndStyle).cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = bounds
    }

    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = bounds
        gradient.cornerRadius = 12
        gradient.masksToBounds = true
        layer.insertSublayer(gradient, at: 0)

        gradientLayer = gradient
    }
}
