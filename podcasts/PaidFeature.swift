import Combine
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

// MARK: - Features

extension PaidFeature {
    static var bookmarks: PaidFeature = .plusFeature
    static var deselectChapters: PaidFeature = .inEarlyAccess
    static var slumber: PaidFeature = .plusFeature
}

/// A `PaidFeature` represents a feature that is unlocked with a subscription tier, and is considered to be unlocked if the tier
/// is equal to or higher than the set `tier` value.
///
/// The unlock state is self managed by listening for relevant notifications and updating the `isUnlocked` property accordingly.
///
/// Since this is a subclass of `ObservableObject` it can easily be used in SwiftUI. Outside SwiftUI, you can use the `objectWillChange`
/// publisher to be notified about changes.
///
/// And while the class is an `ObservableObject` it doesn't use any `@Published` properties and instead manually triggers `objectWillChange`.
/// This is done to ensure future compatibility of any property changes by not allowing listeners to directly access a published properties publisher.
///
class PaidFeature: ObservableObject {
    /// Whether the feature is unlocked for the active subscription tier
    var isUnlocked: Bool {
        subscriptionHelper.activeTier >= tier
    }

    /// The minimum subscription level required to unlock this feature
    let tier: SubscriptionTier

    /// Whether the feature is in its early access period or not.
    ///
    /// Internally this doesn't change anything with the feature, but allows the app to check its state and display different UI if needed.
    let inEarlyAccess: Bool

    /// The static class to use to check for the active subscription.
    private let subscriptionHelper: SubscriptionHelper

    private var cancellables = Set<AnyCancellable>()

    /// Creates a new paid feature with a minimum tier
    /// - Parameters:
    ///   - tier: The minimum tier required to unlock
    ///   - betaTier: The minimum tier required when running in the app beta
    ///   - inEarlyAccess: Whether this feature is in its early access period or not.
    init(tier: SubscriptionTier,
         betaTier: SubscriptionTier? = nil,
         inEarlyAccess: Bool = false,
         subscriptionHelper: SubscriptionHelper = .shared,
         buildEnvironment: BuildEnvironment = .current) {
        if let betaTier, buildEnvironment == .testFlight {
            self.tier = betaTier
        } else {
            self.tier = tier
        }

        self.inEarlyAccess = inEarlyAccess
        self.subscriptionHelper = subscriptionHelper

        addListeners()
    }

    /// Listen for changes and update the internal state
    private func addListeners() {
        Publishers.Merge(
            ServerNotifications.iapPurchaseCompleted.publisher(),
            ServerNotifications.subscriptionStatusChanged.publisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
}

// MARK: - Helpers

#if !os(watchOS)
extension PaidFeature {
    /// Returns the correct upgrade view controller for the feature
    func upgradeController(source: String, customTitle: String? = nil) -> UIViewController {
        OnboardingFlow.shared.begin(flow: upgradeFlow, source: source, customTitle: customTitle)
    }

    /// Presents the `upgradeController` from the given view controller
    func presentUpgradeController(from controller: UIViewController, source: String, customTitle: String? = nil) {
        controller.presentFromRootController(upgradeController(source: source, customTitle: customTitle))
    }

    private var upgradeFlow: OnboardingFlow.Flow {
        switch tier {
        case .patron:
            return .patronAccountUpgrade
        default:
            return .plusUpsell
        }
    }
}
#endif


// MARK: - Private: Feature State Helpers

private extension PaidFeature {
    /// A `PaidFeature` that is currently in early access.
    ///
    /// - Available to Patron users on the AppStore
    /// - Available to Plus users during beta
    /// - Has the `inEarlyAccess` flag set to True
    static var inEarlyAccess: PaidFeature {
        .init(tier: .patron, betaTier: .plus, inEarlyAccess: true)
    }

    /// A `PaidFeature` that is available to Patron subscribers.
    ///
    /// - Available to Patron users on the AppStore and Beta.
    /// - The `inEarlyAccess` flag is set to False
    static var patronFeature: PaidFeature {
        .init(tier: .patron)
    }

    /// A `PaidFeature` that is available to Plus and Patron subscribers.
    ///
    /// - Available to Plus and Patron users on the AppStore and Beta.
    /// - The `inEarlyAccess` flag is set to False
    static var plusFeature: PaidFeature {
        .init(tier: .plus)
    }
}
