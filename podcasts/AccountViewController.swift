import PocketCastsServer
import PocketCastsUtils
import UIKit

class AccountViewController: UIViewController, ChangeEmailDelegate {
    enum TableRow { case upgradeView, changeEmail, changePassword, upgradeAccount, newsletter, cancelSubscription, logout, deleteAccount, privacyPolicy, termsOfUse, supporterContributions }
    var tableData: [[TableRow]] = [[.changeEmail, .changePassword, .newsletter], [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]

    static let newsletterCellId = "NewsletterCellId"
    static let actionCellId = "AccountActionCellId"

    private var isUsernamePasswordLogin: Bool {
        ServerSettings.syncingPassword() != nil
    }

    @IBOutlet var tableView: ThemeableTable! {
        didSet {
            tableView.applyInsetForMiniPlayer()
            tableView.register(UINib(nibName: "NewsletterCell", bundle: nil), forCellReuseIdentifier: AccountViewController.newsletterCellId)
            tableView.register(UINib(nibName: "AccountActionCell", bundle: nil), forCellReuseIdentifier: AccountViewController.actionCellId)
            tableView.register(PlusAccountPromptTableCell.self, forCellReuseIdentifier: PlusAccountPromptTableCell.reuseIdentifier)
        }
    }

    var upgradePromptViewSize: CGSize? = nil {
        didSet {
            tableView.reloadData()
        }
    }

    lazy var headerViewModel: AccountHeaderViewModel = {
        let viewModel = AccountHeaderViewModel()

        viewModel.viewContentSizeChanged = { [weak self] in
            self?.tableView.reloadData()
        }

        return viewModel
    }()

    lazy var updatedHeaderContentView: UIView = {
        let headerView = AccountHeaderView(viewModel: headerViewModel)

        let view = headerView.themedUIView
        view.backgroundColor = .clear

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.accountTitle

        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsFailed), name: ServerNotifications.iapProductsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusChanged), name: ServerNotifications.subscriptionStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        tableView.tableHeaderView = updatedHeaderContentView
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
        headerViewModel.update()

        // Show the upsell if the users subscription is expiring in the next 30 days
        let isExpiring = (SubscriptionHelper.timeToSubscriptionExpiry() ?? .infinity) < Constants.Limits.maxSubscriptionExpirySeconds

        // Show the 'Upgrade Account' if the user has an active subscription that isn't patron.
        // Hide the cell if we're already showing the big upgrade prompt
        let upgradeRow = (SubscriptionHelper.activeTier == .plus && !isExpiring) ? TableRow.upgradeAccount : nil

        // Only accounts created with username/password can change email/password
        var accountOptions: [TableRow]
        if isUsernamePasswordLogin {
            accountOptions = [.changeEmail, .changePassword, upgradeRow, .newsletter].compactMap { $0 }
        } else {
            accountOptions = [upgradeRow, .newsletter].compactMap { $0 }
        }

        if SubscriptionHelper.hasActiveSubscription() {
            var newTableRows: [[TableRow]] = [accountOptions, [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]

            if SubscriptionHelper.activeSubscriptionType != .none {
                newTableRows[0].append(.cancelSubscription)
            }

            if !SubscriptionHelper.hasRenewingSubscription() && !SubscriptionHelper.hasLifetimeGift() && isExpiring {
                newTableRows[0].insert(.upgradeView, at: 0)
            }

            updateTableRows(newRows: newTableRows)

        } else {
            var newTableRows: [[TableRow]] = [accountOptions, [.privacyPolicy, .termsOfUse], [.logout], [.deleteAccount]]

            if let subscriptionPodcasts = SubscriptionHelper.subscriptionPodcasts(), subscriptionPodcasts.count > 0 {
                newTableRows[0].insert(.supporterContributions, at: 0)
            }

            newTableRows[0].insert(.upgradeView, at: 0)

            updateTableRows(newRows: newTableRows)
        }
    }

    @objc func iapProductsUpdated() {
        updateDisplayedData()
    }

    @objc func iapProductsFailed() {
        updateDisplayedData()
    }

    private func updateTableRows(newRows: [[TableRow]]) {
        guard tableData != newRows else { return }

        tableData = newRows
        tableView.reloadData()
    }

    // MARK: - Actions

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
            self.headerViewModel.update()
        }
    }
}
