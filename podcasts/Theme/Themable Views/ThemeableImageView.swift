import UIKit

class ThemeableImageView: UIImageView {
    var imageNameFunc: (() -> String)? {
        didSet {
            updateImage()
        }
    }

    var imageStyle: ThemeStyle? {
        didSet {
            updateImage()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        updateImage()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc func themeDidChange() {
        updateImage()
    }

    private func updateImage() {
        if let imageName = imageNameFunc {
            image = UIImage(named: imageName())
        } else if let imageStyle = imageStyle, let currentImage = image {
            image = currentImage.tintedImage(AppTheme.colorForStyle(imageStyle))
        }
    }
}
