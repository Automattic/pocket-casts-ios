import SwiftUI
import PocketCastsServer
import PocketCastsUtils
import StoreKit

@MainActor
@Observable
class SubscriptionInfoViewModel {

    var isLoading: Bool = true
    var price: String?

    func refresh(isiOS: Bool, tier: SubscriptionTier, frequency: SubscriptionFrequency) async {
        if isiOS, let productID = resolveProductID(tier: tier, frequency: frequency) {
            price = await getSubscriptionPrice(productID: productID.rawValue)
        }
        isLoading = false
    }

    func resolveProductID(tier: SubscriptionTier, frequency: SubscriptionFrequency) -> IAPProductID? {
        let plan: Plan
        switch tier {
        case .plus:
            plan = .plus
        case .patron:
            plan = .patron
        case .none:
            return nil
        }
        switch frequency {
        case .yearly:
            return plan.yearly
        case .monthly:
            return plan.monthly
        case .none:
            return nil
        }
    }

    func getSubscriptionPrice(productID: String) async -> String? {
        guard
            let products = try? await Product.products(for: [productID]),
            let product = products.first
        else {
            return nil
        }
        return product.displayPrice
    }
}

struct SubscriptionInfoView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @State var model = SubscriptionInfoViewModel()

    var plan: String {
        "\(coordinator.userState.subscriptionTier.localizedDescription) \(coordinator.userState.frequency.localizedDescription)"
    }

    var length: String {
        if case .lifetime = coordinator.userState.subscriptionStatus {
            return "Lifetime"
        }
        return DateFormatHelper.sharedHelper.longLocalizedFormat(coordinator.userState.expirationDate)
    }

    var body: some View {
        VStack(spacing: 48) {
            Text("Subscription")
                .font(.headline)
                .foregroundStyle(Color.pcTextPrimary)
            if case .freeAccount = coordinator.userState.subscriptionStatus {
                Text(L10n.accountDetailsFreeAccount)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
                    .wrappingMultiline()
            } else {
                InfoRow(label: "Plan", value: self.plan)
                InfoRow(label: "Next renewal", value: self.length)
                if model.isLoading {
                    ProgressView()
                } else {
                    if let price = model.price {
                        InfoRow(label: "Price", value: price)
                    } else {
                        Text("This subscription was made on another platform. Please use that platform to manage the subscription.")
                            .font(.caption)
                            .foregroundStyle(Color.pcTextSecondary)
                            .wrappingMultiline()
                    }
                }
            }
        }
        .frame(maxWidth: 800)
        .padding(80)
        .task {
            await model.refresh(isiOS: coordinator.userState.platform == .iOS, tier: coordinator.userState.subscriptionTier, frequency: coordinator.userState.frequency)
        }
    }
}

struct InfoRow: View {

    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.pcTextPrimary)
                .wrappingMultiline()
        }
        .frame(minWidth: 400, maxWidth: 500)
    }
}

private struct WrappingMultiline: ViewModifier {
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension View {
    func wrappingMultiline() -> some View {
        modifier(WrappingMultiline())
    }
}

private extension SubscriptionTier {
    var localizedDescription: String {
        switch self {
        case .none:
            return "None"
        case .plus:
            return L10n.pocketCastsPlusShort
        case .patron:
            return L10n.patron
        }
    }
}

private extension SubscriptionFrequency {

    var localizedDescription: String {
        switch self {
        case .none:
            return ""
        case .monthly:
            return L10n.monthly
        case .yearly:
            return L10n.yearly
        }
    }
}

#Preview {
    SubscriptionInfoView()
        .environment(AppCoordinator())
}
