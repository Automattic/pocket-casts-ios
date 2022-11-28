import Foundation

struct OnboardingFlow {
    static var shared = OnboardingFlow()

    private var currentFlow: Flow = .none
    private var source: String? = nil

    mutating func begin(flow: Flow, in controller: UIViewController? = nil, source: String? = nil) -> UIViewController {
        self.currentFlow = flow
        self.source = source

        let navigationController = controller as? UINavigationController

        let flowController: UIViewController
        switch flow {
        case .plusUpsell:
            // Only the upsell flow needs an unknown source
            self.source = source ?? "unknown"
            flowController = PlusLandingViewModel.make(in: navigationController, from: .upsell, upgradeSource: source)

        case .plusAccountUpgrade:
            flowController = PlusPurchaseModel.make(in: controller)

        case .plusAccountUpgradeNeedsLogin:
            flowController = LoginCoordinator.make(in: navigationController, fromUpgrade: true)

        case .initialOnboarding, .loggedOut: fallthrough
        default:
            flowController = LoginCoordinator.make(in: navigationController)
        }

        return flowController
    }

    mutating func reset() {
        source = nil
        currentFlow = .none
    }

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var defaultProperties: [String: Any] = ["flow": currentFlow]

        // Append the source, only if it's set
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

        /// When the user taps on an upgrade button but is logged out and needs to login
        /// They are presented with the login first, then the modal
        case plusAccountUpgradeNeedsLogin = "plus_account_upgrade_needs_login"

        /// When the user is logged out and enters the login flow
        /// This is the same as the onboarding flow
        case loggedOut = "logged_out"

        var analyticsDescription: String { rawValue }
    }
}
