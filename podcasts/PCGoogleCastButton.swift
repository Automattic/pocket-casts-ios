import GoogleCast
import UIKit

class PCGoogleCastButton: UIButton {
    private static let disconnectedIconName = "nav_cast_off"
    private static let connectedIconName = "nav_cast_on"
    private static let animatedIconNames = ["nav_cast_on0", "nav_cast_on1", "nav_cast_on2"]

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else {
            NotificationCenter.default.removeObserver(self, name: Constants.Notifications.googleCastStatusChanged, object: nil)
            return
        }
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.googleCastStatusChanged, object: nil)
    }

    func setup() {
        updateForCurrentState()
        NotificationCenter.default.addObserver(self, selector: #selector(stateDidChange), name: Constants.Notifications.googleCastStatusChanged, object: nil)
    }

    @objc private func stateDidChange() {
        updateForCurrentState()
    }

    private func updateForCurrentState() {
        if GoogleCastManager.sharedManager.connected() {
            setImageOnAllStates(imageName: PCGoogleCastButton.connectedIconName)
        } else if GoogleCastManager.sharedManager.connecting() {
            imageView?.animationImages = createAnimationImages()
            imageView?.animationDuration = 1.0
            imageView?.startAnimating()
        } else {
            setImageOnAllStates(imageName: PCGoogleCastButton.disconnectedIconName)
        }
    }

    private func setImageOnAllStates(imageName: String) {
        imageView?.stopAnimating()
        setImage(UIImage(named: imageName), for: .normal)
        setImage(UIImage(named: imageName), for: .selected)
        setImage(UIImage(named: imageName), for: .highlighted)
    }

    private func createAnimationImages() -> [UIImage] {
        var images = [UIImage]()
        for imageName in PCGoogleCastButton.animatedIconNames {
            if let image = UIImage(named: imageName), let tintedImage = image.tintedImage(tintColor) {
                images.append(tintedImage)
            }
        }

        return images
    }
}
