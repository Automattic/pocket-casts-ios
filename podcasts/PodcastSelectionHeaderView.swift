
import UIKit

class PodcastSelectionHeaderView: UIView {
    @IBOutlet var contentView: ThemeableView! {
        didSet {
            contentView.style = .primaryUi01
        }
    }

    @IBOutlet var selectAllSwitch: ThemeableSwitch!
    @IBOutlet var titleLabel: UILabel! {
        didSet {
            titleLabel.text = L10n.filterCreatePodcastsAllPodcasts
        }
    }

    @IBOutlet var subtitleLabel: ThemeableLabel! {
        didSet {
            subtitleLabel.style = .secondaryText01
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadViewFromNib() {
        Bundle.main.loadNibNamed("PodcastSelectionHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.anchorToAllSidesOf(view: self)
    }
}
