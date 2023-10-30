import Foundation

struct OnboardingFlow {
    typealias Context = [String: Any]

    static var shared = OnboardingFlow()

    private(set) var currentFlow: Flow = .none
    private var source: String? = nil

    mutating func begin(flow: Flow, in controller: UIViewController? = nil, source: String? = nil, context: Context? = nil) -> UIViewController {
        self.currentFlow = flow
        self.source = source

        let navigationController = controller as? UINavigationController

        let flowController: UIViewController
        switch flow {
        case .plusUpsell, .endOfYearUpsell:
            // Only the upsell flow needs an unknown source
            self.source = source ?? "unknown"
            flowController = upgradeController(in: navigationController, context: context)

        case .plusAccountUpgrade:
            if FeatureFlag.patron.enabled {
                self.source = source ?? "unknown"
                flowController = upgradeController(in: navigationController, context: context)
            } else {
                flowController = PlusPurchaseModel.make(in: controller, plan: .plus, selectedPrice: .yearly)
            }

        case .patronAccountUpgrade:
            self.source = source ?? "unknown"
            let config = PlusLandingViewModel.Config(products: [.patron], displayProduct: .init(plan: .patron, frequency: .yearly))

            flowController = PlusLandingViewModel.make(in: navigationController,
                                                       from: .upsell,
                                                       config: config)

        case .plusAccountUpgradeNeedsLogin:
            flowController = LoginCoordinator.make(in: navigationController, continuePurchasing: .init(plan: .plus, frequency: .yearly))

        case .initialOnboarding, .loggedOut: fallthrough
        default:
            flowController = LoginCoordinator.make(in: navigationController)
        }

        return flowController
    }

    private func upgradeController(in controller: UINavigationController?, context: Context?) -> UIViewController {
        let product = context?["product"] as? Constants.ProductInfo
        return PlusLandingViewModel.make(in: controller, from: .upsell, config: .init(displayProduct: product))
    }

    /// Resets the internal flow state to none and clears any analytics sources
    mutating func reset() {
        source = nil
        currentFlow = .none

        NotificationCenter.default.post(name: .onboardingFlowDidDismiss, object: nil)
    }

    /// Updates the source passed for analytics
    /// Any `track` events will use this new source
    mutating func updateAnalyticsSource(_ source: String) {
        self.source = source
    }

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var defaultProperties: [String: Any] = ["flow": currentFlow]

        // Append the source, only if it's set because not every event needs a source
        if let source {
            defaultProperties["source"] = source
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

        var analyticsDescription: String { rawValue }

        /// If after a successful sign in or sign up the onboarding flow
        /// should be dismissed right away
        var shouldDismiss: Bool {
            switch self {
            case .sonosLink, .forcedLoggedOut:
                return true
            default:
                return false
            }
        }
    }
}
