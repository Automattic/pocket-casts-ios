
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
            titleLabel.font = UIFont.font(ofSize: 18, weight: .regular, scalingWith: .headline)
            titleLabel.numberOfLines = 0
            titleLabel.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var subtitleLabel: ThemeableLabel! {
        didSet {
            subtitleLabel.style = .secondaryText01
            subtitleLabel.numberOfLines = 0
            subtitleLabel.adjustsFontForContentSizeCategory = true
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.anchorToAllSidesOf(view: self)
    }
}
