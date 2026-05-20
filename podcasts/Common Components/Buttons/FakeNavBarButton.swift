import UIKit

/// Implemented by buttons that participate in the navigation bar's scroll-edge chrome transition.
/// `PCViewController` walks its bar items and forwards `setTransparentNavBarScrolled` to any
/// custom view that conforms.
protocol FakeNavBarStylable {
    func setNavBarScrolled(_ scrolled: Bool, animated: Bool)
}

/// A 32x32 circular pill button styled to sit on a transparent navigation bar.
/// At the scroll edge: white icon over a translucent dark background — visible over artwork.
/// Scrolled: theme primary icon over a clear background — blends into the bar's blur material.
final class FakeNavBarButton: UIButton, FakeNavBarStylable {
    init(image: UIImage?, accessibilityLabel: String, target: Any?, action: Selector) {
        super.init(frame: .zero)
        setImage(image, for: .normal)
        addTarget(target, action: action, for: .touchUpInside)
        self.accessibilityLabel = accessibilityLabel
        Self.applyStyle(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns a bar button suitable for `useTransparentNavigationBarAppearance`.
    /// On Liquid Glass (iOS 26+), returns a plain `UIBarButtonItem`: the bar's adaptive material
    /// gives correct contrast on its own. On earlier OS versions, wraps a `FakeNavBarButton` so the
    /// icon stays visible over both the at-edge artwork and the scrolled blur.
    static func makeBarButtonItem(image: UIImage?, accessibilityLabel: String, target: Any?, action: Selector) -> UIBarButtonItem {
        if LiquidGlass.isEnabled {
            let item = UIBarButtonItem(image: image, style: .plain, target: target, action: action)
            item.accessibilityLabel = accessibilityLabel
            return item
        }
        let button = FakeNavBarButton(image: image, accessibilityLabel: accessibilityLabel, target: target, action: action)
        return UIBarButtonItem(customView: button)
    }

    func setNavBarScrolled(_ scrolled: Bool, animated: Bool) {
        Self.applyChrome(to: self, scrolled: scrolled, animated: animated)
    }

    /// Applies the standard size, corner radius, and initial transparent chrome to any UIButton.
    /// Used for buttons that can't subclass `NavBarButton` (e.g. `PCGoogleCastButton`).
    static func applyStyle(to button: UIButton) {
        let buttonSize: CGFloat = 32
        let imageSize: CGFloat = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = buttonSize / 2
        button.layer.masksToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.isPointerInteractionEnabled = true
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize),
        ])
        if let imageView = button.imageView {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: imageSize),
                imageView.heightAnchor.constraint(equalToConstant: imageSize),
            ])
        }
        applyChrome(to: button, scrolled: false, animated: false)
    }

    /// Crossfades a UIButton's tint and background between the at-edge and scrolled chromes.
    static func applyChrome(to button: UIButton, scrolled: Bool, animated: Bool) {
        if animated {
            let transition = CATransition()
            transition.duration = Constants.Animation.defaultAnimationTime
            transition.type = .fade
            button.layer.add(transition, forKey: "navBarChromeFade")
        }
        button.tintColor = scrolled ? ThemeColor.primaryIcon01() : .white
        button.backgroundColor = scrolled ? .clear : UIColor.black.withAlphaComponent(0.35)
    }
}
