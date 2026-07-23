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
        switch(tier, frequency) {
        case (.plus, .monthly):
            return .monthly
        case (.plus, .yearly):
            return .yearly
        case (.patron, .yearly):
            return .patronYearly
        case (.patron, .monthly):
            return .patronMonthly
        default:
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
        var result = ""
        result = coordinator.userState.subscriptionTier.localizedDescription
        result += " "
        result += coordinator.userState.frequency.localizedDescription
        return result
    }

    var length: String {
        var result = ""
        if case SubscriptionStatus.lifetime = coordinator.userState.subscriptionStatus {
            result = "Lifetime"
            return result
        }
        result = DateFormatHelper.sharedHelper.longLocalizedFormat(coordinator.userState.expirationDate)
        return result
    }

    var price: String? {
        model.price
    }

    var body: some View {
        VStack(spacing: 48) {
            Text("Subscription")
                .font(.headline)
                .foregroundStyle(Color.pcTextPrimary)
            if case .freeAccount = coordinator.userState.subscriptionStatus {
                Text("Free Account")
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
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
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
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
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 400, maxWidth: 500)
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
