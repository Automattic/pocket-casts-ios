import PocketCastsServer
import UIKit

class SelectPaymentFreqViewController: UIViewController {
    @IBOutlet var plusLogo: ThemeableImageView! {
        didSet {
            plusLogo.imageNameFunc = AppTheme.pcPlusLogoHorizontalImageName
        }
    }

    @IBOutlet var monthlyBorderView: ThemeableSelectionView! {
        didSet {
            monthlyBorderView.isSelected = true
            monthlyBorderView.style = .primaryField02
            monthlyBorderView.layer.cornerRadius = 6
            monthlyBorderView.layer.borderWidth = 2
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(monthlyTapped))
            monthlyBorderView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var monthlyButton: UIButton! {
        didSet {
            monthlyButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
            monthlyButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        }
    }

    @IBOutlet var yearlyBorderView: ThemeableSelectionView! {
        didSet {
            yearlyBorderView.isSelected = false
            yearlyBorderView.style = .primaryField02
            yearlyBorderView.layer.cornerRadius = 6
            yearlyBorderView.layer.borderWidth = 2
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(yearlyTapped))
            yearlyBorderView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var monthlyTitleLabel: ThemeableLabel!
    @IBOutlet var monthlyPriceLabel: ThemeableLabel!
    @IBOutlet var monthlyTrialLabel: ThemeableLabel!

    @IBOutlet var yearlyTitleLabel: ThemeableLabel!
    @IBOutlet var yearlyPriceLabel: ThemeableLabel!
    @IBOutlet var yearlyTrialLabel: ThemeableLabel!

    @IBOutlet var yearlyButton: UIButton! {
        didSet {
            yearlyButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
            yearlyButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        }
    }

    @IBOutlet var nextButton: ThemeableRoundedButton!
    @IBOutlet var discountLabel: ThemeableLabel! {
        didSet {
            discountLabel.style = .primaryField03Active
        }
    }

    @IBOutlet var yearlyDiscountLabel: ThemeableLabel! {
        didSet {
            yearlyDiscountLabel.style = .primaryField03Active
        }
    }

    @IBOutlet var noConnectionImageView: ThemeableImageView! {
        didSet {
            noConnectionImageView.imageNameFunc = AppTheme.noConnectionImageName
        }
    }

    @IBOutlet var errorView: ThemeableView!
    @IBOutlet var tryAgainActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var tryAgainButton: ThemeableRoundedButton!

    @IBOutlet var errorDetailLabel: ThemeableLabel!
    var monthlyPrice: Float = 1.0
    var yearlyPrice: Float = 10.0
    private var isYearly: Bool = true {
        didSet {
            if isYearly {
                yearlyButton.isSelected = true
                yearlyBorderView.isSelected = true
                monthlyButton.isSelected = false
                monthlyBorderView.isSelected = false
            } else {
                yearlyButton.isSelected = false
                yearlyBorderView.isSelected = false
                monthlyButton.isSelected = true
                monthlyBorderView.isSelected = true
            }
        }
    }

    var newSubscription: NewSubscription

    init(newSubscription: NewSubscription) {
        self.newSubscription = newSubscription
        super.init(nibName: "SelectPaymentFreqViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLabels()
        isYearly = true

        title = L10n.plusSelectPaymentFrequency

        monthlyTitleLabel.text = L10n.monthly
        yearlyTitleLabel.text = L10n.yearly
        nextButton.setTitle(L10n.next, for: .normal)

        let backButton = UIBarButtonItem(image: UIImage(named: "nav-back"), style: .done, target: self, action: #selector(backTapped(_:)))
        backButton.accessibilityLabel = L10n.back
        navigationItem.leftBarButtonItem = backButton

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsFailed), name: ServerNotifications.iapProductsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        errorView.isHidden = true

        Analytics.track(.selectPaymentFrequencyShown)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @IBAction func nextTapped(_ sender: Any) {
        newSubscription.iap_identifier = isYearly ? Constants.IapProducts.yearly.rawValue : Constants.IapProducts.monthly.rawValue

        Analytics.track(.selectPaymentFrequencyNextButtonTapped, properties: ["product": newSubscription.iap_identifier])
        AnalyticsHelper.plusAddToCart(identifier: newSubscription.iap_identifier)

        if newSubscription.isNewAccount {
            let newEmailVC = NewEmailViewController(newSubscription: newSubscription)
            navigationController?.pushViewController(newEmailVC, animated: true)
        } else {
            let confirmPaymentVC = ConfirmPaymentViewController(newSubscription: newSubscription)
            navigationController?.pushViewController(confirmPaymentVC, animated: true)
        }
    }

    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        Analytics.track(.selectPaymentFrequencyDismissed)
    }

    @IBAction func tryAgainTapped(_ sender: Any) {
        tryAgainActivityIndicator.isHidden = false
        tryAgainButton.isEnabled = false
        tryAgainActivityIndicator.startAnimating()
        configureLabels()
    }

    // MARK: - Helper functions

    @IBAction func yearlyTapped(_ sender: Any) {
        isYearly = true
    }

    @IBAction func monthlyTapped() {
        isYearly = false
    }

    @objc func iapProductsUpdated() {
        errorView.isHidden = true
        tryAgainActivityIndicator.stopAnimating()
        configureLabels()
    }

    @objc func iapProductsFailed() {
        #if !targetEnvironment(simulator)
            errorView.isHidden = false
            tryAgainButton.isEnabled = true
            tryAgainActivityIndicator.stopAnimating()
        #endif
    }

    @objc private func themeDidChange() {
        yearlyButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
        yearlyButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
        monthlyButton.setImage(UIImage(named: "radio-unselected")?.tintedImage(ThemeColor.primaryField03()), for: .normal)
        monthlyButton.setImage(UIImage(named: "radio-selected")?.tintedImage(ThemeColor.primaryField03Active()), for: .selected)
    }
}

// MARK: - Pricing Labels

private extension SelectPaymentFreqViewController {
    private func configureLabels() {
        updateYearlyLabel()
        updateMonthlyLabel()
    }

    func updateMonthlyLabel() {
        guard let trialDuration = IapHelper.shared.localizedFreeTrialDuration(.monthly) else {
            monthlyPriceLabel.text = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)
            monthlyTrialLabel.isHidden = true
            return
        }

        let price = IapHelper.shared.pricingStringWithFrequency(for: .monthly)
        monthlyPriceLabel.text = L10n.freeTrialDurationFree(trialDuration).localizedLowercase
        monthlyTrialLabel.text = L10n.pricingTermsAfterTrial(price ?? "")
        monthlyTrialLabel.style = .primaryText02
    }

    func updateYearlyLabel() {
        guard let trialDuration = IapHelper.shared.localizedFreeTrialDuration(.yearly) else {
            let yearlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.yearly.rawValue)
            nextButton.isEnabled = !yearlyPrice.isEmpty
            nextButton.buttonStyle = nextButton.isEnabled ? .primaryInteractive01 : .primaryUi05

            yearlyPriceLabel.text = yearlyPrice
            yearlyTrialLabel.isHidden = true
            yearlyDiscountLabel.isHidden = true
            discountLabel.text = L10n.plusPaymentFrequencyBestValue.localizedUppercase

            return
        }

        let price = IapHelper.shared.pricingStringWithFrequency(for: .yearly)
        yearlyPriceLabel.text = L10n.freeTrialDurationFree(trialDuration).localizedLowercase
        yearlyTrialLabel.text = L10n.pricingTermsAfterTrial(price ?? "")
        yearlyDiscountLabel.text = L10n.plusPaymentFrequencyBestValue.localizedUppercase
        yearlyTrialLabel.style = .primaryText02

        discountLabel.isHidden = true
        yearlyDiscountLabel.isHidden = false
    }
}
