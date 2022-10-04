import UIKit

class SmartInvertImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()

        accessibilityIgnoresInvertColors = true
    }
}
