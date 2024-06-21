import Combine
import GravatarUI
import PocketCastsServer
import PocketCastsUtils
import UIKit
import SafariServices

class AccountViewController: UIViewController, ChangeEmailDelegate {
    enum UIConstants {
        enum Gravatar {
            static let padding: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
        }
    }
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

    lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [gravatarProfileViewContainer, updatedHeaderContentView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var gravatarProfileViewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gravatarProfileView)
        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 16
        NSLayoutConstraint.activate([
            gravatarProfileView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            gravatarProfileView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            gravatarProfileView.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalPadding),
            gravatarProfileView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalPadding)
        ])
        return view
    }()

    private lazy var gravatarProfileView: UIView & UIContentView = {
        let contentView = LargeProfileSummaryView(avatarType: .custom(self))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        return contentView
    }()

    private let gravatarViewModel: ProfileViewModel = .init()

    private var cancellables = Set<AnyCancellable>()

    private lazy var gravatarConfiguration: ProfileViewConfiguration = {
        return ProfileViewConfiguration.largeSummary().updatedForPocketCasts(delegate: self)
    }() {
        didSet {
            gravatarProfileView.configuration = gravatarConfiguration
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
            tableView.reloadData()
        }
    }

    lazy var updatedHeaderContentView: UIView = {
        let headerView = AccountHeaderView(viewModel: headerViewModel)

        let view = headerView.themedUIView
        view.backgroundColor = .clear

        return view
    }()

    private lazy var subscriptionAvatarView: UIView = {
        let view = SubscriptionProfileImage(viewModel: headerViewModel)
            .frame(width: ProfileHeaderView.Constants.imageSize, height: ProfileHeaderView.Constants.imageSize)
        let avatarView = view.themedUIView
        avatarView.backgroundColor = .clear
        return avatarView
    }()

    private func toggleGravatarProfileView() {
        gravatarProfileViewContainer.isHidden = !headerViewModel.shouldDisplayGravatarProfile
        if headerViewModel.shouldDisplayGravatarProfile {
            fetchGravatarProfile()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.accountTitle

        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsFailed), name: ServerNotifications.iapProductsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(subscriptionStatusChanged), name: ServerNotifications.subscriptionStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        tableView.tableHeaderView = headerStackView
        tableView.widthAnchor.constraint(equalTo: headerStackView.widthAnchor).isActive = true
        receiveGravatarViewModelUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayedData()
        title = L10n.accountTitle
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        title = ""
        if FeatureFlag.newAccountUpgradePromptFlow.enabled {
            OnboardingFlow.shared.reset()
        }
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
        toggleGravatarProfileView()
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

            if SubscriptionHelper.hasRenewingSubscription() {
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

extension AccountViewController: ProfileViewDelegate {

    private func receiveGravatarViewModelUpdates() {
        gravatarViewModel.$profileFetchingResult.sink { [weak self] result in
            guard let self else { return }
            guard let result else {
                var newConfig = self.gravatarConfiguration.updatedForPocketCasts(delegate: self)
                newConfig.model = nil
                newConfig.summaryModel = nil
                self.gravatarConfiguration = newConfig
                return
            }

            switch result {
            case .success(let profile):
                var newConfig = self.gravatarConfiguration.updatedForPocketCasts(delegate: self)
                newConfig.model = profile
                newConfig.summaryModel = profile
                self.gravatarConfiguration = newConfig
            case .failure(Gravatar.APIError.responseError(reason: let reason)) where reason.httpStatusCode == 404:
                // No Gravatar profile found, switch to the "claim profile" state.
                var claimProfileConfig = ProfileViewConfiguration.claimProfile(profileStyle: gravatarConfiguration.profileStyle)
                claimProfileConfig.padding = UIConstants.Gravatar.padding
                claimProfileConfig.delegate = self
                claimProfileConfig.palette = .custom(Palette.pocketCasts)
                self.gravatarConfiguration = claimProfileConfig
            case .failure:
                // TODO: handle error
                break
            }
        }.store(in: &cancellables)

        gravatarViewModel.$isLoading.sink { [weak self] isLoading in
            guard let self else { return }
            var newConfig = self.gravatarConfiguration
            newConfig.isLoading = isLoading
            self.gravatarConfiguration = newConfig
        }.store(in: &cancellables)
    }

    public func clearGravatarProfile() {
        gravatarViewModel.clear()
    }

    public func fetchGravatarProfile() {
        guard headerViewModel.shouldDisplayGravatarProfile, let email = headerViewModel.profile.email else { return }
        Task {
            await gravatarViewModel.fetchProfile(profileIdentifier: ProfileIdentifier.email(email))
        }
    }

    func profileView(_ view: GravatarUI.BaseProfileView, didTapOnProfileButtonWithStyle style: GravatarUI.ProfileButtonStyle, profileURL: URL?) {
        guard let profileURL else { return }
        let safari = SFSafariViewController(url: profileURL)
        present(safari, animated: true)
    }

    func profileView(_ view: GravatarUI.BaseProfileView, didTapOnAccountButtonWithModel accountModel: any GravatarUI.AccountModel) {
        guard let accountURL = accountModel.accountURL else { return }
        let safari = SFSafariViewController(url: accountURL)
        present(safari, animated: true)
    }

    func profileView(_ view: GravatarUI.BaseProfileView, didTapOnAvatarWithID avatarID: Gravatar.AvatarIdentifier?) {}
}

extension AccountViewController: AvatarProviding {
    var avatarView: UIView {
        subscriptionAvatarView
    }

    func setImage(with source: URL?, placeholder: UIImage?, options: [GravatarUI.ImageSettingOption]?) async throws {
        // no need
    }

    func setImage(_ image: UIImage?) {
        // no need
    }

    func refresh(with paletteType: GravatarUI.PaletteType) {
        // no need
    }
}

fileprivate extension ProfileViewConfiguration {

    func updatedForPocketCasts(delegate: ProfileViewDelegate) -> ProfileViewConfiguration {
        var config = self
        config.padding = AccountViewController.UIConstants.Gravatar.padding
        config.profileButtonStyle = .edit
        config.delegate = delegate
        config.palette = .custom(Palette.pocketCasts)
        return config
    }
}

extension Palette {
    static func pocketCasts() -> GravatarUI.Palette {
        GravatarUI.Palette(
            name: Theme.sharedTheme.activeTheme.description,
            foreground: ForegroundColors(primary: ThemeColor.primaryText01(),
                                         primarySlightlyDimmed: ThemeColor.secondaryText01(),
                                         secondary: ThemeColor.primaryText02()),
            background: BackgroundColors(primary: ThemeColor.primaryUi01()),
            avatar: AvatarColors(border: ThemeColor.primaryUi05(),
                                 background: ThemeColor.primaryUi04()),
            border: ThemeColor.primaryUi05(),
            placeholder: PlaceholderColors(backgroundColor: ThemeColor.primaryText01().withAlphaComponent(0.05),
                                           loadingAnimationColors: [
                                            ThemeColor.primaryText01().withAlphaComponent(0.05),
                                            ThemeColor.primaryText01().withAlphaComponent(0.1)
                                           ]),
            preferredUserInterfaceStyle: Theme.sharedTheme.activeTheme.isDark ? .dark: .light
        )
    }
}
