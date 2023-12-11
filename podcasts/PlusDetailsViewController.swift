import PocketCastsServer
import UIKit

class PlusDetailsViewController: PCViewController {
    @IBOutlet var topPriceLabel: UILabel!
    @IBOutlet var bottomPriceLabel: UILabel!
    @IBOutlet var plusLogo: UIImageView!

    private let gradientLayer = CAGradientLayer()
    @IBOutlet var gradientView: UIView! {
        didSet {
            gradientLayer.colors = [ThemeColor.gradient01A().cgColor, ThemeColor.gradient01E().cgColor]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradientLayer.frame = gradientView.bounds
            gradientView.layer.addSublayer(gradientLayer)
        }
    }

    @IBOutlet var plusTiledView: UIView! {
        didSet {
            plusTiledView.backgroundColor = UIColor(patternImage: UIImage(named: "plusSingleTile")!)
        }
    }

    @IBOutlet var learnMoreBtn: UIButton! {
        didSet {
            learnMoreBtn.setTitle(L10n.plusMarketingLearnMoreButton, for: .normal)
        }
    }

    // top section
    @IBOutlet var mainTitle: ThemeableLabel! {
        didSet {
            mainTitle.text = L10n.plusMarketingMainTitle
        }
    }

    @IBOutlet var plusDescription: SecondaryLabel! {
        didSet {
            plusDescription.text = L10n.plusMarketingMainDescription
        }
    }

    @IBOutlet var upgradeButton: GradientButton! {
        didSet {
            upgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
        }
    }

    @IBOutlet var secondUpgradeButton: GradientButton! {
        didSet {
            secondUpgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
        }
    }

    // Features
    @IBOutlet var desktopAppsTitle: ThemeableLabel! {
        didSet {
            desktopAppsTitle.text = L10n.plusMarketingDesktopAppsTitle
        }
    }

    @IBOutlet var desktopAppsDescription: SecondaryLabel! {
        didSet {
            desktopAppsDescription.text = L10n.plusMarketingDesktopAppsDescription
        }
    }

    @IBOutlet var cloudStorageTitle: ThemeableLabel! {
        didSet {
            cloudStorageTitle.text = L10n.plusMarketingCloudStorageTitle
        }
    }

    @IBOutlet var cloudStorageDescription: SecondaryLabel! {
        didSet {
            cloudStorageDescription.text = L10n.plusMarketingCloudStorageDescription
        }
    }

    @IBOutlet var watchPlaybackTitle: ThemeableLabel! {
        didSet {
            watchPlaybackTitle.text = L10n.plusMarketingWatchPlaybackTitle
        }
    }

    @IBOutlet var watchPlaybackDescription: SecondaryLabel! {
        didSet {
            watchPlaybackDescription.text = L10n.plusMarketingWatchPlaybackDescription
        }
    }

    @IBOutlet var foldersTitle: ThemeableLabel! {
        didSet {
            foldersTitle.text = L10n.folders
        }
    }

    @IBOutlet var foldersDescription: SecondaryLabel! {
        didSet {
            foldersDescription.text = L10n.plusMarketingFoldersDescription
        }
    }

    @IBOutlet var themesTitle: ThemeableLabel! {
        didSet {
            themesTitle.text = L10n.plusMarketingThemesIconsTitle
        }
    }

    @IBOutlet var themesDescription: SecondaryLabel! {
        didSet {
            themesDescription.text = L10n.plusMarketingThemesIconsDescription
        }
    }

    @IBOutlet var finalCallToAction: SecondaryLabel! {
        didSet {
            finalCallToAction.text = L10n.plusMarketingFinalCallToAction
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)

        title = L10n.pocketCastsPlus
        loadPrices()
        handleThemeChanged()

        Analytics.track(.settingsPlusShown)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let viewToMatch = gradientView?.superview {
            gradientLayer.frame = viewToMatch.bounds
        }
    }

    @IBAction func upgradeTapped(_ sender: Any) {
        let source = PlusAccountPromptViewModel.Source.plusDetails
        if SyncManager.isUserLoggedIn() {
            let model = PlusAccountPromptViewModel()
            model.parentController = self
            model.source = source
            model.upgradeTapped()
        } else {
            present(OnboardingFlow.shared.begin(flow: .plusAccountUpgradeNeedsLogin, source: source.rawValue), animated: true)
        }

        Analytics.track(.settingsPlusUpgradeButtonTapped)
    }

    @IBAction func learnMoreTapped(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
        Analytics.track(.settingsPlusLearnMoreTapped)
    }

    @objc private func iapProductsUpdated() {
        loadPrices()
    }

    override func handleThemeChanged() {
        let plusIconName = Theme.sharedTheme.activeTheme.isDark ? "verticalLogoDark" : "verticalLogo"
        plusLogo.image = UIImage(named: plusIconName)

        gradientLayer.colors = [ThemeColor.gradient01A().cgColor, ThemeColor.gradient01E().cgColor]

        learnMoreBtn.setTitleColor(ThemeColor.primaryInteractive01(), for: .normal)
    }
}

// MARK: - Pricing Labels

private extension PlusDetailsViewController {
    private func loadPrices() {
        guard let trialDetails = IapHelper.shared.getFirstFreeTrialDetails() else {
            updatePricingLabels()
            return
        }

        // Update the pricing labels with trial information
        let pricingText = L10n.freeTrialPricingTerms(trialDetails.duration, trialDetails.pricing)
        topPriceLabel.text = pricingText
        bottomPriceLabel.text = pricingText

        // Update the upgrade buttons with the start free trial title
        let buttonTitle = L10n.freeTrialStartButton
        upgradeButton.setTitle(buttonTitle, for: .normal)
        secondUpgradeButton.setTitle(buttonTitle, for: .normal)
    }

    private func updatePricingLabels() {
        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)
        let yearlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.yearly.rawValue)

        if monthlyPrice.count > 0, yearlyPrice.count > 0 {
            let priceText = L10n.settingsPlusPricingFormat(monthlyPrice, yearlyPrice)
            topPriceLabel.text = priceText
            bottomPriceLabel.text = priceText
        }
    }
}
