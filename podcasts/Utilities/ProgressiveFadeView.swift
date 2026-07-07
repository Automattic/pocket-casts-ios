import UIKit

/// A vertical gradient overlay fading from transparent at the top to a solid color at the
/// bottom, giving a soft fade-out edge.
///
/// Used instead of the system scroll edge effect, which washes out over busy multicolor
/// content like a grid of podcast artwork. Fading the content into its own background
/// color dissolves it cleanly behind floating bottom bars.
///
/// The alpha is baked into the gradient rather than masking an opaque view with a
/// `CAGradientLayer`: the mask isn't honored when the Liquid Glass tab bar snapshots its
/// backdrop on expand, which would flash a solid rectangle at the top edge.
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
        gradientLayer.locations = [0, 0.33, 1]
        setColor(color)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets the fade color: transparent at the top ramping to solid at the bottom.
    /// Pass `nil` for no fade.
    func setColor(_ color: UIColor?) {
        let color = color ?? .clear
        gradientLayer.colors = [color.withAlphaComponent(0).cgColor, color.withAlphaComponent(0.5).cgColor, color.cgColor]
    }
}
