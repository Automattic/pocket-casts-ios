import PocketCastsServer
import PocketCastsUtils
import UIKit

class SelectAccountTypeViewController: UIViewController {
    @IBOutlet var plusNameLabel: ThemeableLabel!

    @IBOutlet var freeBorderView: ThemeableSelectionView! {
        didSet {
            freeBorderView.isSelected = true
            freeBorderView.style = .primaryField02
            freeBorderView.layer.cornerRadius = 6
            freeBorderView.layer.borderWidth = 2
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(freeTapped))
            freeBorderView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var freeRadioButton: UIButton! {
        didSet {
            freeRadioButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
            freeRadioButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        }
    }

    @IBOutlet var plusBorderView: ThemeableSelectionView! {
        didSet {
            plusBorderView.isSelected = false
            plusBorderView.style = .primaryField02
            plusBorderView.layer.cornerRadius = 6
            plusBorderView.layer.borderWidth = 2
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(plusTapped))
            plusBorderView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var plusRadioButton: UIButton! {
        didSet {
            plusRadioButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
            plusRadioButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        }
    }

    @IBOutlet var freeLabel: ThemeableLabel! {
        didSet {
            freeLabel.text = L10n.createAccountFreePrice.localizedUppercase
        }
    }

    @IBOutlet var plusPriceLabel: ThemeableLabel!
    @IBOutlet var regularLabel: ThemeableLabel! {
        didSet {
            regularLabel.text = L10n.createAccountFreeAccountType
        }
    }

    @IBOutlet var almostEverythingLabel: ThemeableLabel! {
        didSet {
            almostEverythingLabel.text = L10n.createAccountFreeDetails
            almostEverythingLabel.style = .primaryText02
        }
    }

    @IBOutlet var plusPaymentFreqLabel: ThemeableLabel! {
        didSet {
            plusPaymentFreqLabel.style = .primaryText02
        }
    }

    @IBOutlet var everythingLabel: ThemeableLabel! {
        didSet {
            everythingLabel.text = L10n.createAccountPlusDetails
            everythingLabel.style = .primaryText02
        }
    }

    @IBOutlet var nextButton: ThemeableRoundedButton! {
        didSet {
            nextButton.setTitle(L10n.next, for: .normal)
        }
    }

    @IBOutlet var seperatorView: ThemeableView! {
        didSet {
            seperatorView.style = .primaryUi05
        }
    }

    @IBOutlet var plusLogoImageView: ThemeableImageView! {
        didSet {
            plusLogoImageView.imageNameFunc = AppTheme.pcPlusLogoHorizontalImageName
        }
    }

    @IBOutlet var plusFeatureView: PlusFeaturesView!

    @IBOutlet var learnMoreButton: UIButton! {
        didSet {
            learnMoreButton.setTitle(L10n.createAccountFindOutMorePlus, for: .normal)
            learnMoreButton.backgroundColor = UIColor.clear
            learnMoreButton.setTitleColor(ThemeColor.primaryInteractive01(), for: .normal)
        }
    }

    @IBOutlet var errorView: ThemeableView!
    @IBOutlet var tryAgainActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var tryAgainButton: ThemeableRoundedButton!

    @IBOutlet var errorMessageTitle: ThemeableLabel! {
        didSet {
            errorMessageTitle.text = L10n.createAccountAppStoreErrorTitle
        }
    }

    @IBOutlet var errorDetailLabel: ThemeableLabel! {
        didSet {
            errorDetailLabel.text = L10n.createAccountAppStoreErrorMessage
            errorDetailLabel.style = .primaryText02
        }
    }

    @IBOutlet var noConnectionImageView: ThemeableImageView! {
        didSet {
            noConnectionImageView.imageNameFunc = AppTheme.noConnectionImageName
        }
    }

    var isFreeAccount = true {
        didSet {
            if isFreeAccount {
                freeRadioButton.isSelected = true
                plusRadioButton.isSelected = false
                freeBorderView.isSelected = true
                plusBorderView.isSelected = false
            } else {
                freeRadioButton.isSelected = false
                plusRadioButton.isSelected = true
                freeBorderView.isSelected = false
                plusBorderView.isSelected = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.accountSelectType
        isFreeAccount = false
        configureLabels()
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped(_:)))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsFailed), name: ServerNotifications.iapProductsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        errorView.isHidden = true
        Analytics.track(.selectAccountTypeShown)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actions

    @IBAction func nextTapped(_ sender: Any) {
        let newSubscription = NewSubscription(isNewAccount: true, iap_identifier: "")
        if isFreeAccount {
            let enailVC = NewEmailViewController(newSubscription: newSubscription)
            navigationController?.pushViewController(enailVC, animated: true)
        } else {
            let termsOfUseVC = TermsViewController(newSubscription: newSubscription)
            navigationController?.pushViewController(termsOfUseVC, animated: true)
        }

        let accountType = isFreeAccount ? "free" : "plus"
        Analytics.track(.selectAccountTypeNextButtonTapped, properties: ["account_type": accountType])
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        Analytics.track(.selectAccountTypeDismissed)
    }

    @IBAction func learnMoreTapped(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
    }

    @IBAction func plusTapped(_ sender: Any) {
        isFreeAccount = false
    }

    @IBAction func freeTapped(_ sender: Any) {
        isFreeAccount = true
    }

    @IBAction func tryAgainTapped(_ sender: Any) {
        tryAgainActivityIndicator.isHidden = false
        tryAgainButton.isEnabled = false
        tryAgainActivityIndicator.startAnimating()
        configureLabels()
    }

    @objc func iapProductsUpdated() {
        errorView.isHidden = true
        configureLabels()
    }

    @objc private func iapProductsFailed() {
        #if !targetEnvironment(simulator)
            tryAgainButton.isEnabled = true
            tryAgainActivityIndicator.stopAnimating()
            errorView.isHidden = false
        #endif
    }

    @objc private func themeDidChange() {
        plusRadioButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
        plusRadioButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        freeRadioButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
        freeRadioButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        learnMoreButton.setTitleColor(ThemeColor.primaryInteractive01(), for: .normal)
    }
}

// MARK: - Free Trials

private extension SelectAccountTypeViewController {
    private func configureLabels() {
        guard let trialDetails = IapHelper.shared.getFirstFreeTrialDetails() else {
            configurePricingLabels()
            return
        }
        plusNameLabel.text = L10n.pocketCastsPlusShort
        plusPriceLabel.text = L10n.freeTrialDurationFree(trialDetails.duration)
        plusPaymentFreqLabel.text = L10n.pricingTermsAfterTrial(trialDetails.pricing)
    }

    private func configurePricingLabels() {
        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)

        plusNameLabel.text = L10n.pocketCastsPlus

        if monthlyPrice.count > 0 {
            plusPriceLabel.text = monthlyPrice
            plusPaymentFreqLabel.text = L10n.plusPerMonth
            nextButton.isEnabled = true
        } else {
            #if targetEnvironment(simulator)
                nextButton.isEnabled = true

            #else
                nextButton.isEnabled = false
            #endif
        }
    }
}
