import Foundation
import PocketCastsUtils

struct OnboardingFlow {
    typealias Context = [String: Any]

    static var shared = OnboardingFlow()

    private(set) var currentFlow: Flow = .none
    private(set) var source: PlusUpgradeViewSource? = nil

    private(set) var accountCreated: ((Bool)->())?

    mutating func begin(flow: Flow, in controller: UIViewController? = nil, source: PlusUpgradeViewSource, context: Context? = nil, customTitle: String? = nil, accountCreated: ((Bool)->())? = nil) -> UIViewController {
        self.currentFlow = flow
        self.source = source
        self.accountCreated = accountCreated

        let navigationController = controller as? UINavigationController

        let flowController: UIViewController
        switch flow {
        case .plusUpsell, .endOfYearUpsell, .suggestedFolderUpsell:
            // Only the upsell flow needs an unknown source
            self.source = source
            flowController = upgradeController(in: navigationController,
                                               viewSource: source,
                                               context: context,
                                               customTitle: customTitle)

        case .plusAccountUpgrade:
            self.source = source
            let product = context?["product"] as? ProductInfo
            if FeatureFlag.newOnboardingUpgrade.enabled {
                flowController = UpgradeAccountViewModel.make(in: controller,
                                                              flowSource: .accountScreen,
                                                              viewSource: source,
                                                              plan: product?.plan ?? .plus,
                                                              frequency: product?.frequency ?? .yearly)
            } else {
                flowController = PlusPurchaseModel.make(in: controller,
                                                        plan: product?.plan ?? .plus,
                                                        selectedPrice: product?.frequency ?? .yearly,
                                                        customTitle: customTitle)
            }

        case .patronAccountUpgrade:
            self.source = source
            if FeatureFlag.newOnboardingUpgrade.enabled {
                flowController = UpgradeAccountViewModel.make(in: controller,
                                                              flowSource: .upsell,
                                                              viewSource: source,
                                                              plan: .patron,
                                                              frequency: .yearly,
                                                              )
            } else {
                let config = PlusLandingViewModel.Config(products: [.patron], displayProduct: .init(plan: .patron, frequency: .yearly))
                flowController = PlusLandingViewModel.make(in: navigationController,
                                                           from: .upsell,
                                                           viewSource: source,
                                                           config: config,
                                                           customTitle: customTitle)
            }

        case .plusAccountUpgradeNeedsLogin:
            flowController = LoginCoordinator.make(in: navigationController, continuePurchasing: .init(plan: .plus, frequency: .yearly))

        case .encourageAccountCreation:
            flowController = InformationalModalViewModel.makeController()

        case .initialOnboarding:
            flowController = LoginCoordinator.make(in: navigationController, isOnboarding: true)
        default:
            flowController = LoginCoordinator.make(in: navigationController, isOnboarding: false)
        }

        return flowController
    }

    private func upgradeController(in controller: UINavigationController?, viewSource: PlusUpgradeViewSource, context: Context?, customTitle: String? = nil) -> UIViewController {
        let product = context?["product"] as? ProductInfo
        if FeatureFlag.newOnboardingUpgrade.enabled {
            return UpgradeAccountViewModel.make(in: controller,
                                                flowSource: .upsell,
                                                viewSource: viewSource,
                                                plan: product?.plan ?? .plus,
                                                frequency: product?.frequency ?? .yearly)
        } else {
            return PlusLandingViewModel.make(in: controller,
                                             from: .upsell,
                                             viewSource: viewSource,
                                             config: .init(displayProduct: product),
                                             customTitle: customTitle)
        }
    }

    /// Resets the internal flow state to none and clears any analytics sources
    mutating func reset() {
        if (currentFlow == .initialOnboarding) || (currentFlow == .encourageAccountCreation) {
            NavigationManager.sharedManager.showNotificationsPermissionsModal()
        }
        source = .unknown
        currentFlow = .none

        NotificationCenter.default.post(name: .onboardingFlowDidDismiss, object: nil)
    }

    /// Updates the source passed for analytics
    /// Any `track` events will use this new source
    mutating func updateAnalyticsSource(_ source: PlusUpgradeViewSource) {
        self.source = source
    }

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var defaultProperties: [String: Any] = ["flow": currentFlow]

        // Append the source, only if it's set because not every event needs a source
        if let source {
            defaultProperties["source"] = source.rawValue
        }

        let mergedProperties = defaultProperties.merging(properties ?? [:]) { current, _ in current }
        Analytics.track(event, properties: mergedProperties)
    }

    // MARK: - Flow
    enum Flow: String, AnalyticsDescribable {
        /// Default state / not currently in a flow.. not tracked
        case none

        /// When the app first launches, and the user is asked to login/create account
        case initialOnboarding = "initial_onboarding"

        /// When the user taps on a locked feature or upsell dialog and is brought to the plus landing view
        case plusUpsell = "plus_upsell"

        /// When the user taps on an upgrade button and is brought directly to the purchase modal
        /// From account details and plus details
        case plusAccountUpgrade = "plus_account_upgrade"

        /// When the user taps the 'Upgrade Account' option from the account view to view the patron upgrade view
        case patronAccountUpgrade = "patron_account_upgrade"

        /// When the user taps on an upgrade button but is logged out and needs to login
        /// They are presented with the login first, then the modal
        case plusAccountUpgradeNeedsLogin = "plus_account_upgrade_needs_login"

        /// When the user is logged out and enters the login flow
        /// This is the same as the onboarding flow
        case loggedOut = "logged_out"

        /// When the user is brought into the onboarding flow from the Sonos connect view
        /// After the user logs in or creates an account, the flow is dismissed so they can
        /// continue with the Sonos connection process
        case sonosLink = "sonos_link"

        /// When the user was logged out due to a server or token issue, not as a result of user interaction and is
        /// asked to sign in again. See the `BackgroundSignOutListener`
        case forcedLoggedOut = "forced_logged_out"

        /// When the user is brought into the onboarding flow from the End Of Year prompt
        case endOfYear

        /// When the user is brought into the onboarding flow from the End Of Year stories
        case endOfYearUpsell

        case suggestedFolderUpsell = "suggested_folder_upsell"

        case promoCode = "promo_code"

        case referralCode = "referral_code"

        case encourageAccountCreation = "encourage_account_creation"

        var analyticsDescription: String { rawValue }

        /// If after a successful sign in or sign up the onboarding flow
        /// should be dismissed right away
        var shouldDismiss: Bool {
            switch self {
            case .sonosLink, .forcedLoggedOut, .promoCode, .referralCode:
                return true
            default:
                return false
            }
        }

        /// If after a successful purchase the flow should be
        /// dismissed right away
        var shouldDismissAfterPurchase: Bool {
            switch self {
            case .endOfYearUpsell, .suggestedFolderUpsell:
                true
            default:
                false
            }
        }
    }
}
