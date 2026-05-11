import UIKit

/// Trailing reorder grabber for a collection-view cell.
///
/// The handle is added on top of the cell and a horizontal gradient mask is
/// applied to the cell's `contentView`, so content sitting under the handle
/// (badges, hearts, etc.) fades out to transparent rather than being pushed
/// aside by a layout change. The handle and the mask are created lazily on
/// the first show.
final class CellReorderHandle {
    private static let handleSize: CGFloat = 24
    private static let trailingInset: CGFloat = 16
    private static let fadeWidth: CGFloat = 40
    private static let animationDuration: CFTimeInterval = 0.2

    private unowned let cell: UICollectionViewCell
    private var handleView: UIImageView?
    private var maskLayer: CAGradientLayer?

    init(cell: UICollectionViewCell) {
        self.cell = cell
    }

    var isVisible: Bool = false {
        didSet {
            guard isVisible != oldValue else { return }
            isVisible ? show() : hide()
        }
    }

    /// Call from the cell's `layoutSubviews()` so the gradient tracks size changes.
    func updateLayout() {
        guard isVisible, let maskLayer else { return }
        let bounds = cell.contentView.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = bounds
        maskLayer.locations = openLocations(for: bounds.width)
        CATransaction.commit()
    }

    private func show() {
        let handle = ensureHandle()
        let mask = ensureMask()
        cell.contentView.layer.mask = mask
        mask.frame = cell.contentView.bounds
        animateMask(to: openLocations(for: cell.contentView.bounds.width), curve: .easeOut)
        UIView.animate(withDuration: Self.animationDuration) {
            handle.alpha = 1
        }
    }

    private func hide() {
        guard let handle = handleView, let mask = maskLayer else { return }
        animateMask(to: closedLocations, curve: .easeIn)
        UIView.animate(withDuration: Self.animationDuration, animations: {
            handle.alpha = 0
        }, completion: { [weak self] _ in
            guard let self, !self.isVisible else { return }
            self.cell.contentView.layer.mask = nil
        })
    }

    private func animateMask(to target: [NSNumber], curve: CAMediaTimingFunctionName) {
        guard let mask = maskLayer else { return }
        let from = mask.presentation()?.locations ?? mask.locations ?? closedLocations
        mask.removeAnimation(forKey: "locations")
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = from
        animation.toValue = target
        animation.duration = Self.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: curve)
        mask.locations = target
        mask.add(animation, forKey: "locations")
    }

    private func ensureHandle() -> UIImageView {
        if let handleView { return handleView }
        let view = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        view.tintColor = ThemeColor.primaryIcon02()
        view.contentMode = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        cell.addSubview(view)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -Self.trailingInset),
            view.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: Self.handleSize),
            view.heightAnchor.constraint(equalToConstant: Self.handleSize)
        ])
        handleView = view
        return view
    }

    private func ensureMask() -> CAGradientLayer {
        if let maskLayer { return maskLayer }
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = closedLocations
        maskLayer = layer
        return layer
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
