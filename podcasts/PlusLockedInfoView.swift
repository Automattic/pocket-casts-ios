import UIKit

protocol PlusLockedInfoDelegate: AnyObject {
    func closeInfoTapped()
    var displayingViewController: UIViewController { get }
    var displaySource: PlusUpgradeViewSource { get }
}

class PlusLockedInfoView: ThemeableView {
    weak var delegate: PlusLockedInfoDelegate? {
        didSet {
            setInfoLabelText()
        }
    }

    @IBOutlet var contentView: ThemeableView! {
        didSet {
            contentView.style = .primaryUi01
        }
    }

    @IBOutlet var logoImageView: ThemeableImageView! {
        didSet {
            logoImageView.imageNameFunc = AppTheme.pcPlusLogoHorizontalImageName
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText02
            setInfoLabelText()
        }
    }

    @IBOutlet var closeButton: TintableImageButton! {
        didSet {
            closeButton.setImage(UIImage(named: "close"), for: .normal)
            closeButton.tintColor = ThemeColor.primaryIcon02()
        }
    }

    @IBOutlet var learnMoreButton: ThemeableUIButton! {
        didSet {
            learnMoreButton.style = .primaryInteractive01
            learnMoreButton.setTitle(L10n.plusMarketingLearnMoreButton, for: .normal)
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
        Bundle.main.loadNibNamed("PlusLockedInfoView", owner: self, options: nil)
        addSubview(contentView)
        contentView.anchorToAllSidesOf(view: self)
    }

    @IBAction func closeTapped() {
        Analytics.track(.upgradeBannerDismissed, properties: ["source": delegate?.displaySource.rawValue ?? PlusUpgradeViewSource.unknown.rawValue])
        if let delegate = delegate {
            delegate.closeInfoTapped()
        } else {
            contentView.isHidden = true
        }
    }

    @IBAction func learnMoreTapped(_ sender: Any) {
        guard let displayingVC = delegate?.displayingViewController else {
            NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
            return
        }

        let source: PlusUpgradeViewSource = delegate?.displaySource ?? .unknown
        NavigationManager.sharedManager.showUpsellView(from: displayingVC, source: source)
    }

    private func setInfoLabelText() {
        switch delegate?.displaySource {
        case .profile:
            infoLabel.text = L10n.profileHelpSupport
        default:
            infoLabel.text = L10n.plusPromoParagraph
        }
    }
}
