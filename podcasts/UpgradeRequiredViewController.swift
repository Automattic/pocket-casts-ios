import PocketCastsServer
import UIKit

class UpgradeRequiredViewController: PCViewController {
    @IBOutlet var trialDetailLabel: ThemeableLabel! {
        didSet {
            trialDetailLabel.isHidden = true
        }
    }

    @IBOutlet var upgradeButton: ThemeableRoundedButton! {
        didSet {
            upgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
        }
    }

    @IBOutlet var featureInfoView: PlusFeaturesView!
    @IBOutlet var logoImageView: ThemeableImageView! {
        didSet {
            logoImageView.imageNameFunc = AppTheme.pcPlusLogoVerticalImageName
        }
    }

    @IBOutlet var verticalLogo: UIImageView! {
        didSet {
            verticalLogo.image = Theme.isDarkTheme() ? UIImage(named: "verticalLogoDark") : UIImage(named: "verticalLogo")
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText01
            infoLabel.text = L10n.plusRequiredFeature
        }
    }

    @IBOutlet var priceLabel: ThemeableLabel! {
        didSet {
            priceLabel.style = .primaryText02
        }
    }

    @IBOutlet var noThanksButton: ThemeableRoundedButton! {
        didSet {
            noThanksButton.shouldFill = false
            noThanksButton.setTitle(L10n.settingsGeneralNoThanks, for: .normal)
        }
    }

    let source: PlusUpgradeViewSource
    weak var upgradeRootViewController: UIViewController?

    init(upgradeRootViewController: UIViewController, source: PlusUpgradeViewSource) {
        self.upgradeRootViewController = upgradeRootViewController
        self.source = source

        super.init(nibName: "UpgradeRequiredViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        updatePricingLabels()

        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)

        AnalyticsHelper.plusUpgradeViewed(source: source)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    @IBOutlet var learnMoreButton: ThemeableRoundedButton! {
        didSet {
            learnMoreButton.textStyle = .primaryInteractive01
            learnMoreButton.buttonStyle = .primaryUi01
            learnMoreButton.setTitle(L10n.plusMarketingLearnMoreButton, for: .normal)
        }
    }

    @IBAction func learnMoreClicked(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
    }

    @IBAction func doneCicked(_ sender: Any) {
        AnalyticsHelper.plusUpgradeDismissed(source: source)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func upgradeClicked(_ sender: Any) {
        AnalyticsHelper.plusUpgradeConfirmed(source: source)

        dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }

            let presentingController = self.upgradeRootViewController

            if SyncManager.isUserLoggedIn() {
                let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
                presentingController?.present(SJUIUtils.popupNavController(for: TermsViewController(newSubscription: newSubscription)), animated: true)
            } else {
                let profileIntroViewController = ProfileIntroViewController()
                profileIntroViewController.upgradeRootViewController = presentingController
                presentingController?.present(SJUIUtils.popupNavController(for: profileIntroViewController), animated: true)
            }
        })
    }

    @objc func iapProductsUpdated() {
        updatePricingLabels()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

// MARK: - Private: UI Helpers

private extension UpgradeRequiredViewController {
    func configureNavigationBar() {
        title = L10n.pocketCastsPlus

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func updatePricingLabels() {
        updatePriceLabel()
        updateUIForTrialIfNeeded()
    }

    func updatePriceLabel() {
        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)

        priceLabel.text = L10n.plusPricePerMonth(monthlyPrice)
    }
}

// MARK: - Private: Free Trial Support

private extension UpgradeRequiredViewController {
    func updateUIForTrialIfNeeded() {
        guard let trialDetails = IapHelper.shared.getFirstFreeTrialDetails() else {
            trialDetailLabel.isHidden = true
            return
        }

        // Update the labels
        infoLabel.text = L10n.freeTrialTitleLabel(trialDetails.duration)
        trialDetailLabel.text = L10n.freeTrialDetailLabel
        upgradeButton.setTitle(L10n.freeTrialStartButton, for: .normal)

        // Show the detail label, since its hidden by default
        trialDetailLabel.isHidden = false

        // Update the pricing label to show the terms free for X then Y price
        priceLabel.text = L10n.freeTrialPricingTerms(trialDetails.duration, trialDetails.pricing)
    }
}
