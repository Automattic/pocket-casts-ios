import UIKit

/// A blur overlay whose strength ramps from fully transparent at the top to fully
/// blurred at the bottom, producing a soft progressive-blur edge.
///
/// The system scroll edge effect samples the scrolling content, so over busy,
/// multicolor content (such as a grid of podcast artwork) it washes out and barely
/// registers. This view lays a controllable, consistently visible material blur over
/// the bottom of that content so it fades out cleanly behind floating bottom bars.
final class ProgressiveBlurView: UIView {
    private let blurView: UIVisualEffectView
    private let gradientMask = CAGradientLayer()

    init(effect: UIVisualEffect = UIBlurEffect(style: .systemMaterial)) {
        blurView = UIVisualEffectView(effect: effect)
        super.init(frame: .zero)

        // The overlay is purely decorative; it must never intercept touches meant
        // for the content scrolling underneath it.
        isUserInteractionEnabled = false
        blurView.isUserInteractionEnabled = false
        addSubview(blurView)

        // Alpha mask: transparent at the top, opaque at the bottom. Masking the
        // effect view fades the blur in towards the bottom edge.
        gradientMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1)
        blurView.layer.mask = gradientMask
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Swaps the underlying blur material, e.g. to use a lighter material in dark mode
    /// where the same style reads heavier.
    func setBlurEffect(_ effect: UIVisualEffect?) {
        blurView.effect = effect
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // The mask is a CALayer, so disable implicit animations to keep it pinned to
        // the blur view during bounds changes (rotation, safe-area updates).
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blurView.frame = bounds
        gradientMask.frame = bounds
        CATransaction.commit()
    }
}
