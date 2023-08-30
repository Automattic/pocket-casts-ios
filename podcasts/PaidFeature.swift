import Combine
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

// MARK: - Features

/// To add a new feature:
///     1. Add a new static var for the feature name and tier it should be unlocked with
///
///     Template:
///         static var <#FeatureName#>: PaidFeature = .init(tier: <#Tier#>)
///
///     2. Check the unlock state using `PaidFeature.hello.isUnlocked`
///
extension PaidFeature {
    static var bookmarks: PaidFeature = .init(tier: .patron, betaTier: .plus)
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

    /// The static class to use to check for the active subscription.
    private let subscriptionHelper: SubscriptionHelper

    private var cancellables = Set<AnyCancellable>()

    /// Creates a new paid feature with a minimum tier
    /// - Parameters:
    ///   - tier: The minimum tier required to unlock
    ///   - betaTier: The minimum tier required when running in the app beta
    init(tier: SubscriptionTier,
         betaTier: SubscriptionTier? = nil,
         subscriptionHelper: SubscriptionHelper = .shared,
         buildEnvironment: BuildEnvironment = .current) {
        if let betaTier, buildEnvironment == .testFlight {
            self.tier = betaTier
        } else {
            self.tier = tier
        }

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
    func upgradeController(source: String) -> UIViewController {
        OnboardingFlow.shared.begin(flow: upgradeFlow, source: source)
    }

    /// Presents the `upgradeController` from the given view controller
    func presentUpgradeController(from controller: UIViewController, source: String) {
        controller.presentFromRootController(upgradeController(source: source))
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
