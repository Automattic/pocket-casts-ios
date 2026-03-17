import UIKit

class BouncyButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        isPointerInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isPointerInteractionEnabled = true
    }

    var offImage: UIImage? {
        didSet {
            if !currentlyOn {
                setImage(offImage, for: UIControl.State())
            }
        }
    }

    var onImage: UIImage? {
        didSet {
            if currentlyOn {
                setImage(onImage, for: UIControl.State())
            }
        }
    }

    var offAccessibilityLabel: String? {
        didSet {
            updateAccessibilityLabel()
        }
    }

    var onAccessibilityLabel: String? {
        didSet {
            updateAccessibilityLabel()
        }
    }

    var shouldAnimate = false

    var currentlyOn = false {
        didSet {
            updateAccessibilityLabel()
            if !currentlyOn {
                setImage(offImage, for: UIControl.State())
                return
            }

            if shouldAnimate {
                UIView.animate(withDuration: 0.2, delay: 0.1, options: UIView.AnimationOptions.beginFromCurrentState, animations: { () in
                    self.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                }) { _ in
                    self.setImage(self.onImage, for: UIControl.State())

                    UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: { () in
                        self.transform = CGAffineTransform.identity
                    }, completion: nil)
                }
            } else {
                setImage(onImage, for: UIControl.State())
            }
        }
    }

    private func updateAccessibilityLabel() {
        if currentlyOn, let onLabel = onAccessibilityLabel {
            accessibilityLabel = onLabel
        } else if !currentlyOn, let offLabel = offAccessibilityLabel {
            accessibilityLabel = offLabel
        }
    }
}
