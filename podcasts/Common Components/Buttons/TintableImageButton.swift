
import UIKit

class TintableImageButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()

        let defaultImage = image(for: .normal)?.withRenderingMode(.alwaysTemplate)
        super.setImage(defaultImage, for: .normal)

        let selectedImage = image(for: .selected)?.withRenderingMode(.alwaysTemplate)
        super.setImage(selectedImage, for: .selected)
    }

    override var tintColor: UIColor! {
        didSet {
            setTitleColor(tintColor, for: .normal)
        }
    }

    var backgroundTintColor: UIColor? {
        didSet {
            setBackgroundImage(backgroundImage(for: .normal), for: .normal)
        }
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        let tintableImage = image?.withRenderingMode(.alwaysTemplate)
        super.setImage(tintableImage, for: state)
    }

    override func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        guard let color = backgroundTintColor else {
            super.setBackgroundImage(image, for: state)

            return
        }

        let tintedImage = image?.tintedImage(color)
        super.setBackgroundImage(tintedImage, for: state)
    }
}
