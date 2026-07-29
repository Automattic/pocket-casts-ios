import SwiftUI
import StoreKit
import PocketCastsServer

struct SubscriptionInfoView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var product: Product?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 32) {
            if isLoading {
                ProgressView()
            } else if let product {
                subscriptionDetails(for: product)
            } else if coordinator.userState.isPlusUser {
                // Subscription is active but we couldn't load StoreKit product info.
                // Show what we know from SubscriptionHelper.
                fallbackDetails
            } else {
                noSubscriptionView
            }
        }
        .padding(80)
        .frame(width: 862)
        .task {
            await loadProduct()
        }
    }

    // MARK: - Subscription Details (StoreKit product available)

    private func subscriptionDetails(for product: Product) -> some View {
        VStack(spacing: 40) {
            Text(L10n.tvSubscriptionInfoTitle)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)

            VStack(spacing: 24) {
                infoRow(
                    label: L10n.tvSubscriptionInfoName,
                    value: product.displayName
                )

                if let subscription = product.subscription {
                    infoRow(
                        label: L10n.tvSubscriptionInfoLength,
                        value: Self.periodDescription(subscription.subscriptionPeriod)
                    )
                }

                infoRow(
                    label: L10n.tvSubscriptionInfoPrice,
                    value: product.displayPrice
                )
            }
        }
    }

    // MARK: - Fallback (no StoreKit product)

    private var fallbackDetails: some View {
        VStack(spacing: 40) {
            Text(L10n.tvSubscriptionInfoTitle)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)

            VStack(spacing: 24) {
                let tier = SubscriptionHelper.activeTier
                infoRow(
                    label: L10n.tvSubscriptionInfoName,
                    value: "Pocket Casts \(tier.rawValue)"
                )

                let frequency = SubscriptionHelper.subscriptionFrequencyValue()
                infoRow(
                    label: L10n.tvSubscriptionInfoLength,
                    value: frequency == .yearly ? L10n.year : L10n.month
                )
            }
        }
    }

    // MARK: - No Subscription

    private var noSubscriptionView: some View {
        Text(L10n.tvSubscriptionInfoNone)
            .font(.title3)
            .foregroundStyle(Color.pcTextSecondary)
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.pcTextPrimary)
        }
        .frame(maxWidth: 500)
    }

    private func loadProduct() async {
        guard coordinator.userState.isPlusUser else {
            isLoading = false
            return
        }

        let tier = SubscriptionHelper.activeTier
        let frequency = SubscriptionHelper.subscriptionFrequencyValue()
        let productID = Self.productID(tier: tier, frequency: frequency)

        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            // StoreKit product fetch failed — fallback view will show
        }

        isLoading = false
    }

    /// Returns a human-readable description of the subscription period, e.g. "1 Year".
    private static func periodDescription(_ period: Product.SubscriptionPeriod) -> String {
        let count = period.value
        let unitDescription = period.unit.localizedDescription
        return "\(count) \(unitDescription.capitalized)"
    }

    /// Maps subscription tier and frequency to the App Store product identifier.
    private static func productID(tier: SubscriptionTier, frequency: SubscriptionFrequency) -> String {
        switch (tier, frequency) {
        case (.patron, .monthly):
            return "com.pocketcasts.patron_monthly"
        case (.patron, .yearly):
            return "com.pocketcasts.patron_yearly"
        case (_, .monthly):
            return "com.pocketcasts.plus.monthly"
        default:
            return "com.pocketcasts.plus.yearly"
        }
    }
}

#Preview {
    SubscriptionInfoView()
        .environment(AppCoordinator())
}
