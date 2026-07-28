import UIKit

class PlusLockedInfoCell: ThemeableCell {
    @IBOutlet var lockView: PlusLockedInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()

        isAccessibilityElement = false
    }
}
