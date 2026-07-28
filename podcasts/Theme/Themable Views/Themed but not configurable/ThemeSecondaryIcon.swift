import PocketCastsUtils
import UIKit

class ThemeSecondaryIcon: UIImageView {
    var originalImage: UIImage?

    override func awakeFromNib() {
        originalImage = image

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        setTintColorForTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func themeDidChange() {
        setTintColorForTheme()
    }

    private func setTintColorForTheme() {
        image = originalImage?.tintedImage(ThemeColor.primaryIcon02())
    }
}
