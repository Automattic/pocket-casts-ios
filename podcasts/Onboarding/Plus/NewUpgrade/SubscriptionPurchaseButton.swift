import SwiftUI

struct SubscriptionPurchaseButton: View {

    let viewModel: PlusPurchaseModel
    let tier: UpgradeTier
    let frequency: PlanFrequency
    let showPurchaseErrors: Bool
    let action: (() -> Void)?

    init(viewModel: PlusPurchaseModel, tier: UpgradeTier = .plus, frequency: PlanFrequency = .yearly, showPurchaseErrors: Bool = false, action: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.tier = tier
        self.frequency = frequency
        self.showPurchaseErrors = showPurchaseErrors
        self.action = action
    }

    private var purchaseTitle: String {
        guard let subscriptionInfo = viewModel.pricingInfo(for: tier, frequency: frequency) else {
            return tier.buttonLabel
        }

        if let offer = subscriptionInfo.offer {
            if offer.type == .freeTrial {
                return L10n.freeTrialStartButton
            } else if offer.type == .discount {
                return L10n.discountOfferClaimButton(offer.discountPercent)
            }
        }

        return tier.buttonLabel
    }

    private var isLoading: Bool {
        viewModel.priceAvailability == .loading || viewModel.state == .purchasing
    }


    var body: some View {
        let hasError = Binding<Bool>(
            get: {
                self.viewModel.priceAvailability == .failed || (self.showPurchaseErrors && self.viewModel.state == .failed)
            },
            set: { _ in }
        )
        Button(action: {
            action?()
        }, label: {
            VStack {
                Text(purchaseTitle)
                    .font(size: 18, style: .body, weight: .semibold, maxSizeCategory: .extraExtraExtraLarge)
            }
            .transition(.opacity)
            .id("plus_price" + tier.title)
        })
        .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: tier.plan, themeOverride: Theme.shared))
        .alert(isPresented: hasError) {
            Alert(
                title: Text(L10n.plusPurchaseFailed),
                dismissButton: .default(Text(L10n.ok))
            )
        }
    }
}
