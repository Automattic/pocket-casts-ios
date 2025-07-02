import SwiftUI

struct SubscriptionPurchaseButton: View {

    let viewModel: PlusLandingViewModel
    let tier: UpgradeTier = .plus
    let frequency: PlanFrequency = .yearly

    private var purchaseTitle: String {
        guard let subscriptionInfo = viewModel.pricingInfo(for: tier, frequency: frequency) else {
            return tier.buttonLabel
        }

        if subscriptionInfo.offer?.type == .freeTrial {
            return L10n.freeTrialStartButton
        }

        return tier.buttonLabel
    }

    private var isLoading: Bool {
        (viewModel.state == .purchasing) || (viewModel.priceAvailability == .loading)
    }

    var body: some View {
        let hasError = Binding<Bool>(
            get: { self.viewModel.state == .failed },
            set: { _ in }
        )
        Button(action: {
            viewModel.unlockTapped(.init(plan: tier.plan, frequency: frequency))
        }, label: {
            VStack {
                Text(purchaseTitle)
            }
            .transition(.opacity)
            .id("plus_price" + tier.title)
        })
        .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: tier.plan, themeOverride: Theme.sharedTheme))
        .alert(isPresented: hasError) {
            Alert(
                title: Text(L10n.plusPurchaseFailed),
                dismissButton: .default(Text(L10n.ok)) {
                    viewModel.reset()
                }
            )
        }
    }
}
