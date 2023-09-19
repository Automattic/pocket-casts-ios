import UIKit

class PlusFeaturesView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var customStorageLabel: ThemeableLabel! {
        didSet {
            customStorageLabel.text = L10n.plusFeatureCloudStorage
            customStorageLabel.style = .primaryText02
        }
    }

    @IBOutlet var extraThemesLabel: ThemeableLabel! {
        didSet {
            extraThemesLabel.text = L10n.plusFeatureThemesIcons
            extraThemesLabel.style = .primaryText02
        }
    }

    @IBOutlet var extraIconsLabel: ThemeableLabel! {
        didSet {
            extraIconsLabel.text = L10n.plusFeatureWatchApp
            extraIconsLabel.style = .primaryText02
        }
    }

    @IBOutlet var webPlayerLabel: ThemeableLabel! {
        didSet {
            webPlayerLabel.text = L10n.plusFeatureWebPlayer
            webPlayerLabel.style = .primaryText02
        }
    }

    @IBOutlet var foldersLabel: ThemeableLabel! {
        didSet {
            foldersLabel.text = L10n.folders
            foldersLabel.style = .primaryText02
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("PlusFeaturesView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        layoutIfNeeded()
    }

    private func configureLabels() {
        customStorageLabel.text = L10n.plusCloudStorageLimit
    }
}
