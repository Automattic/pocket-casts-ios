import UIKit

/// A vertical gradient overlay that fades from fully transparent at the top to a solid
/// color at the bottom, producing a soft fade-out edge.
///
/// The system scroll edge effect samples the scrolling content, so over busy,
/// multicolor content (such as a grid of podcast artwork) it washes out and barely
/// registers. Rather than blur, this view fades the content into its own background
/// color toward the bottom so it dissolves cleanly behind floating bottom bars.
///
/// The fade is drawn as the layer's own gradient content — not an opaque view behind a
/// `CAGradientLayer` mask. A masked-opaque approach flashes solid at the top edge while
/// the Liquid Glass tab bar captures its backdrop snapshot on expand (the snapshot path
/// doesn't honor the layer mask), so baking the alpha straight into the gradient avoids
/// ever presenting an opaque rectangle.
final class ProgressiveFadeView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(color: UIColor? = nil) {
        super.init(frame: .zero)

        // The overlay is purely decorative; it must never intercept touches meant
        // for the content scrolling underneath it.
        isUserInteractionEnabled = false

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.locations = [0, 0.8, 1]
        setColor(color)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets the fade color: transparent at the top ramping to this color, which then
    /// holds solid across the lower portion. Pass `nil` for no fade.
    func setColor(_ color: UIColor?) {
        let color = color ?? .clear
        // Fade from the *same* color at zero alpha (not `.clear`, which is transparent
        // black) so the ramp doesn't dip through a grey band in the middle.
        gradientLayer.colors = [color.withAlphaComponent(0).cgColor, color.cgColor, color.cgColor]
    }
}
