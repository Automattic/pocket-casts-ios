import GoogleCast
import UIKit

class PCAlwaysVisibleCastBtn: UIButton {
    var inactiveTintColor = UIColor.white {
        didSet {
            tintColor = inactiveTintColor
        }
    }

    var activeTintColor = UIColor.white {
        didSet {
            if oldValue == activeTintColor { return } // no need to do anything if the color hasn't changed

            animationImages = [(UIImage(named: "shelf_nav_cast_on0")?.tintedImage(activeTintColor))!,
                               (UIImage(named: "shelf_nav_cast_on1")?.tintedImage(activeTintColor))!,
                               (UIImage(named: "shelf_nav_cast_on2")?.tintedImage(activeTintColor))!,
                               (UIImage(named: "shelf_nav_cast_on1")?.tintedImage(activeTintColor))!]
        }
    }

    let offImage = UIImage(named: "shelf_nav_cast_off")
    let onImage = UIImage(named: "shelf_nav_cast_on")
    var animationImages = [UIImage(named: "shelf_nav_cast_on0")!, UIImage(named: "shelf_nav_cast_on1")!, UIImage(named: "shelf_nav_cast_on2")!, UIImage(named: "shelf_nav_cast_on1")!]

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
        imageView?.animationDuration = 1.5

        statusDidChange()
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange), name: Constants.Notifications.googleCastStatusChanged, object: nil)
    }

    @objc private func statusDidChange() {
        guard let imageView = imageView else { return }

        if GoogleCastManager.sharedManager.connecting() {
            if !imageView.isAnimating {
                imageView.animationImages = animationImages
                imageView.startAnimating()
            }
        } else if GoogleCastManager.sharedManager.connected() {
            imageView.stopAnimating()
            imageView.animationImages = nil
            tintColor = activeTintColor
            setImage(onImage, for: .normal)
        } else {
            imageView.stopAnimating()
            imageView.animationImages = nil
            tintColor = inactiveTintColor
            setImage(offImage, for: .normal)
        }
    }
}
