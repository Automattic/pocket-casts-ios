
import UIKit

class UserEpisodeActionCell: ThemeableCell {
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var actionImage: UIImageView!
    @IBOutlet var lockImage: UIImageView!

    func setLocked(locked: Bool) {
        contentView.alpha = locked ? 0.5 : 1
        lockImage.isHidden = !locked
    }
}
