
import UIKit

class StatsTopCell: ThemeableCell {
    @IBOutlet var listenLabel: UILabel!
    @IBOutlet var timeLabel: ThemeableLabel! {
        didSet {
            timeLabel.style = .support01
        }
    }

    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var loadingIndicator: AngularActivityIndicator! {
        didSet {
            loadingIndicator.hidesWhenStopped = true
        }
    }

    override func handleThemeDidChange() {
        loadingIndicator.color = AppTheme.loadingActivityColor()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
