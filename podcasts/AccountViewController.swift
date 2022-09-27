import PocketCastsServer
import PocketCastsUtils
import UIKit

class AccountViewController: UIViewController, ChangeEmailDelegate {
    enum TableRow { case changeEmail, changePassword, newsletter, cancelSubscription, logout, deleteAccount, privacyPolicy, termsOfUse, supporterContributions }
    var tableData: [[TableRow]] = [[.changeEmail, .changePassword, .newsletter], [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]
    
    static let newsletterCellId = "NewsletterCellId"
    static let actionCellId = "AccountActionCellId"
    
    @IBOutlet var tableView: ThemeableTable! {
        didSet {
            tableView.applyInsetForMiniPlayer()
            tableView.register(UINib(nibName: "NewsletterCell", bundle: nil), forCellReuseIdentifier: AccountViewController.newsletterCellId)
            tableView.register(UINib(nibName: "AccountActionCell", bundle: nil), forCellReuseIdentifier: AccountViewController.actionCellId)
        }
    }
    
    @IBOutlet var headerView: UIStackView! {
        didSet {
            headerView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    @IBOutlet var headerBackgroundView: ThemeableView! {
        didSet {
            headerBackgroundView.style = .primaryUi02
        }
    }
    
    @IBOutlet var profileView: ProfileProgressCircleView! {
        didSet {
            profileView.style = .primaryUi02
        }
    }
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var emailLabel: ThemeableLabel! {
        didSet {
            emailLabel.style = .primaryText01
        }
    }
    
    @IBOutlet var accountTypeLabel: ThemeableLabel! {
        didSet {
            accountTypeLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var accountDetailsLabel: ThemeableLabel! {
        didSet {
            accountDetailsLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var paymentExpiryLabel: ThemeableLabel! {
        didSet {
            paymentExpiryLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var seperatorView: ThemeableView! {
        didSet {
            seperatorView.style = .primaryUi05
        }
    }
    
    @IBOutlet var upgradeView: ThemeableView!
    @IBOutlet var upgradeSeperatorView: ThemeableView! {
        didSet {
            upgradeSeperatorView.style = .primaryUi05
        }
    }
    
    @IBOutlet var noInternetView: ThemeableView! {
        didSet {
            noInternetView.style = .primaryUi05
            noInternetView.layer.cornerRadius = 8
            noInternetView.layer.borderColor = AppTheme.colorForStyle(.primaryUi06).cgColor
            noInternetView.layer.borderWidth = 1
        }
    }
    
    @IBOutlet var noInternetLabel: ThemeableLabel! {
        didSet {
            noInternetLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var plusLogo: ThemeableImageView! {
        didSet {
            plusLogo.imageNameFunc = AppTheme.pcPlusLogoHorizontalImageName
        }
    }
    
    @IBOutlet var priceLabel: ThemeableLabel! {
        didSet {
            priceLabel.style = .primaryText01
        }
    }
    
    @IBOutlet var upgradeButton: ThemeableRoundedButton!
    
    @IBOutlet var learnMoreButton: ThemeableRoundedButton! {
        didSet {
            learnMoreButton.textStyle = .primaryInteractive01
            learnMoreButton.buttonStyle = .primaryUi01
        }
    }

    @IBOutlet var trialDetailLabel: ThemeableLabel! {
        didSet {
            trialDetailLabel.style = .primaryText02
        }
    }

    @IBOutlet var pricingCenterConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.accountTitle
        
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsFailed), name: ServerNotifications.iapProductsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusChanged), name: ServerNotifications.subscriptionStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        tableView.tableHeaderView = headerView
        
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            headerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayedData()
        title = L10n.accountTitle
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        title = ""
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
    
    @objc private func subscriptionStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.updateDisplayedData()
        }
    }
    
    private func updateDisplayedData() {
        if let email = ServerSettings.syncingEmail() {
            emailLabel.text = email
        }
        
        if SubscriptionHelper.hasActiveSubscription() {
            accountTypeLabel.text = L10n.pocketCastsPlus
            
            profileView.isSubscribed = true
            
            let expiryDate = SubscriptionHelper.subscriptionRenewalDate()
            var hideExpiryDate = true
            
            if SubscriptionHelper.hasRenewingSubscription() {
                if SubscriptionHelper.subscriptionType() == .plus {
                    let nextPaymentDate = DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate)
                    accountDetailsLabel.text = L10n.nextPaymentFormat(nextPaymentDate)
                    paymentExpiryLabel.text = SubscriptionHelper.subscriptionFrequency()
                    upgradeView.isHidden = true
                } else if SubscriptionHelper.subscriptionType() == .supporter {
                    accountDetailsLabel.style = .support02
                    accountDetailsLabel.text = L10n.supporter
                    paymentExpiryLabel.text = L10n.supporterContributionsSubtitle
                    upgradeView.isHidden = true
                }
            } else { // Gifted account
                if SubscriptionHelper.subscriptionPlatform() == .gift {
                    if SubscriptionHelper.hasLifetimeGift() {
                        hideExpiryDate = true
                        upgradeView.isHidden = true
                        accountDetailsLabel.text = L10n.subscriptionsThankYou
                        paymentExpiryLabel.text = L10n.plusLifetimeMembership
                        paymentExpiryLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
                        paymentExpiryLabel.style = .support02
                    } else {
                        let freeTime = Double(SubscriptionHelper.subscriptionGiftDays()).days
                        let freeTimeStr = DateFormatHelper.sharedHelper.shortTimeRemaining(freeTime).capitalized
                        accountDetailsLabel.text = L10n.plusFreeMembershipFormat(freeTimeStr)
                        hideExpiryDate = false
                    }
                } else {
                    if SubscriptionHelper.subscriptionType() == .plus {
                        accountDetailsLabel.text = L10n.plusPaymentCanceled
                        hideExpiryDate = false
                    } else if SubscriptionHelper.subscriptionType() == .supporter {
                        accountDetailsLabel.style = .support05
                        accountDetailsLabel.text = L10n.supporterPaymentCanceled
                        upgradeView.isHidden = true
                    }
                }
            }
            
            var newTableRows: [[TableRow]] = [[.changeEmail, .changePassword, .newsletter], [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]
            if SubscriptionHelper.numActiveSubscriptionBundles() > 0 {
                newTableRows[0].insert(.supporterContributions, at: 0)
            }
            if SubscriptionHelper.hasRenewingSubscription(), SubscriptionHelper.subscriptionType() == .plus {
                newTableRows[0].append(.cancelSubscription)
            }
            updateTableRows(newRows: newTableRows)
            
            if let expiryTime = SubscriptionHelper.timeToSubscriptionExpiry(), let expiryDate = expiryDate {
                if !hideExpiryDate {
                    let time = DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate)
                    paymentExpiryLabel.text = L10n.plusExpirationFormat(time)
                    
                    if expiryTime < 15.days {
                        paymentExpiryLabel.style = .support05
                        upgradeView.isHidden = SubscriptionHelper.hasRenewingSubscription()
                    } else if expiryTime < 30.days {
                        paymentExpiryLabel.style = .support08
                        upgradeView.isHidden = SubscriptionHelper.hasRenewingSubscription()
                    } else {
                        paymentExpiryLabel.style = .primaryText02
                        upgradeView.isHidden = true
                    }
                }
                profileView.secondsTillExpiry = expiryTime
            }
        } else {
            // Free Account
            accountTypeLabel.text = L10n.pocketCasts
            accountDetailsLabel.text = nil
            paymentExpiryLabel.text = nil
            upgradeView.isHidden = false

            profileView.isSubscribed = false
            
            var newTableRows: [[TableRow]] = [[.changeEmail, .changePassword, .newsletter], [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]
            if let subscriptionPodcasts = SubscriptionHelper.subscriptionPodcasts(), subscriptionPodcasts.count > 0 {
                newTableRows[0].insert(.supporterContributions, at: 0)
            }
            updateTableRows(newRows: newTableRows)
        }

        // Hide this by default
        noInternetView.isHidden = true
        
        // If we're not hiding the upgrade view, then refresh the pricing info
        // If the IAP information hasn't been pulled in yet, this method will trigger a refresh and the view will
        // be updated via `iapProductsUpdated`
        if upgradeView.isHidden == false {
            updatePricingLabels()
        }

        // recalculate header height if subscription status changed
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
        }
    }
    
    @objc func iapProductsUpdated() {
        upgradeButton.isHidden = false
        noInternetView.isHidden = true
        updateDisplayedData()
    }
    
    @objc func iapProductsFailed() {
        #if !targetEnvironment(simulator)
            priceLabel.text = ""
            trialDetailLabel.isHidden = true
            upgradeButton.isHidden = true
            noInternetView.isHidden = false
        #endif
    }
    
    private func updateTableRows(newRows: [[TableRow]]) {
        guard tableData != newRows else { return }
        
        tableData = newRows
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func upgradeTapped(_ sender: Any) {
        showUpgradeOptions()
    }
    
    func showUpgradeOptions() {
        let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
        let termsOfUseVC = TermsViewController(newSubscription: newSubscription)
        present(SJUIUtils.popupNavController(for: termsOfUseVC), animated: true, completion: nil)
    }
    
    @objc func newsletterOptInChanged(_ sender: UISwitch) {
        Analytics.track(.newsletterOptInChanged, properties: ["enabled": sender.isOn, "source": "profile"])

        ServerSettings.setMarketingOptIn(sender.isOn)
        ServerSettings.syncSettings()
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
    }
    
    @objc func themeDidChange() {
        updateDisplayedData() // in case the expiry text color neds updating
    }
    
    // MARK: Change email delegate
    
    func emailChanged() {
        DispatchQueue.main.async {
            if let email = ServerSettings.syncingEmail() {
                self.emailLabel.text = email
            }
        }
    }
}

private extension AccountViewController {
    func updatePricingLabels() {
        guard let trialDetails = IapHelper.shared.getFirstFreeTrialDetails() else {
            configurePricingLabels()
            return
        }

        upgradeButton.setTitle(L10n.freeTrialStartButton, for: .normal)
        priceLabel.text = L10n.freeTrialDurationFree(trialDetails.duration).localizedLowercase
        trialDetailLabel.text = L10n.pricingTermsAfterTrial(trialDetails.pricing)
        trialDetailLabel.isHidden = false
        pricingCenterConstraint.constant = 1
        noInternetView.isHidden = true
    }

    func configurePricingLabels() {
        trialDetailLabel.isHidden = true

        guard let price = IapHelper.shared.pricingStringWithFrequency(for: .monthly) else {
            priceLabel.isHidden = true
            return
        }

        priceLabel.isHidden = false
        noInternetView.isHidden = true
        priceLabel.text = price
        upgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
    }
}
