import UIKit

class TintableImageView: UIImageView {
    override init(image: UIImage?) {
        super.init(image: image)

        super.image = image?.tintedImage(tintColor)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        super.image = image?.tintedImage(tintColor)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        super.image = image?.tintedImage(tintColor)
    }

    override var tintColor: UIColor! {
        didSet {
            super.image = image?.tintedImage(tintColor)
        }
    }
}
