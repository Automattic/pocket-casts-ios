import UIKit

final class StatusBarScrimView: UIView {
    private static let fadeHeight: CGFloat = 32
    private static let maxAlpha: CGFloat = 0.8

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    private var statusBarHeight: CGFloat {
        window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    override var intrinsicContentSize: CGSize {
        let statusBarHeight = statusBarHeight
        let height = statusBarHeight > 0 ? statusBarHeight + Self.fadeHeight : 0
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        NotificationCenter.default.addObserver(self, selector: #selector(updateGradient), name: Constants.Notifications.themeChanged, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        invalidateIntrinsicContentSize()
        updateGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateGradient()
    }

    @objc private func updateGradient() {
        let height = intrinsicContentSize.height
        let solidLocation = height > 0 ? NSNumber(value: Double((height - Self.fadeHeight) / height)) : 1
        let color = ThemeColor.primaryUi01().resolvedColor(with: traitCollection)
        gradientLayer.colors = [
            color.withAlphaComponent(Self.maxAlpha).cgColor,
            color.withAlphaComponent(Self.maxAlpha).cgColor,
            color.withAlphaComponent(0).cgColor
        ]
        gradientLayer.locations = [0, solidLocation, 1]
    }
}
