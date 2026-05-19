import UIKit

/// Trailing reorder grabber for a collection-view cell.
///
/// Added as a sibling of the cell's `contentView`, sized to the cell. While
/// visible, a horizontal gradient mask is applied to the masked view (the
/// cell's `contentView`) so content sitting under the handle (badges, hearts,
/// etc.) fades out to transparent rather than being pushed aside by a layout
/// change.
final class CellReorderHandleView: UIView {
    private static let handleSize: CGFloat = 24
    private static let trailingInset: CGFloat = 16
    private static let fadeWidth: CGFloat = 40
    private static let animationDuration: CFTimeInterval = 0.2

    private weak var maskedView: UIView?
    private let handleImageView: UIImageView
    private let gradientMask = CAGradientLayer()

    var isVisible: Bool = false {
        didSet {
            guard isVisible != oldValue else { return }
            isVisible ? show() : hide()
        }
    }

    init(maskedView: UIView) {
        self.maskedView = maskedView

        let imageView = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        imageView.tintColor = ThemeColor.primaryIcon02()
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        self.handleImageView = imageView

        super.init(frame: .zero)

        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.trailingInset),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: Self.handleSize),
            imageView.heightAnchor.constraint(equalToConstant: Self.handleSize)
        ])

        gradientMask.colors = [
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
        ]
        gradientMask.locations = closedLocations
        applyGradientDirection(to: gradientMask)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func themeDidChange() {
        handleImageView.tintColor = ThemeColor.primaryIcon02()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isVisible, let maskedView else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientMask.frame = maskedView.bounds
        applyGradientDirection(to: gradientMask)
        gradientMask.locations = openLocations(for: maskedView.bounds.width)
        CATransaction.commit()
    }

    private func show() {
        guard let maskedView else { return }
        maskedView.layer.mask = gradientMask
        gradientMask.frame = maskedView.bounds
        applyGradientDirection(to: gradientMask)
        animateMask(to: openLocations(for: maskedView.bounds.width), curve: .easeOut)
        UIView.animate(withDuration: Self.animationDuration) {
            self.handleImageView.alpha = 1
        }
    }

    private func hide() {
        animateMask(to: closedLocations, curve: .easeIn)
        UIView.animate(withDuration: Self.animationDuration, animations: {
            self.handleImageView.alpha = 0
        }, completion: { [weak self] _ in
            guard let self, !self.isVisible else { return }
            self.maskedView?.layer.mask = nil
        })
    }

    private func animateMask(to target: [NSNumber], curve: CAMediaTimingFunctionName) {
        let from = gradientMask.presentation()?.locations ?? gradientMask.locations ?? closedLocations
        gradientMask.removeAnimation(forKey: "locations")
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = from
        animation.toValue = target
        animation.duration = Self.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: curve)
        gradientMask.locations = target
        gradientMask.add(animation, forKey: "locations")
    }

    private func applyGradientDirection(to layer: CAGradientLayer) {
        // CALayers don't auto-mirror, so flip the gradient axis when the handle
        // sits on the leading edge in RTL.
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        layer.startPoint = CGPoint(x: isRTL ? 1 : 0, y: 0.5)
        layer.endPoint = CGPoint(x: isRTL ? 0 : 1, y: 0.5)
    }

    private var closedLocations: [NSNumber] {
        [0, 1, 1, 1]
    }

    private func openLocations(for width: CGFloat) -> [NSNumber] {
        guard width > 0 else { return closedLocations }
        let handleStart = width - (Self.handleSize + Self.trailingInset)
        let fadeStart = max(0, handleStart - Self.fadeWidth)
        return [
            0,
            NSNumber(value: Float(fadeStart / width)),
            NSNumber(value: Float(handleStart / width)),
            1
        ]
    }
}
