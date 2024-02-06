import SwiftUI
import PocketCastsServer

struct UpgradePrompt: View {
    @ObservedObject var viewModel: PlusLandingViewModel
    @EnvironmentObject var theme: Theme
    /// Allows UIKit to listen for content size changes
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

    private let tiers: [UpgradeTier]
    private var selectedTier: UpgradeTier {
        tiers[currentPage]
    }

    @State private var purchaseButtonHeight: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var currentSubscriptionPeriod: PlanFrequency = .yearly

    init(viewModel: PlusLandingViewModel, contentSizeUpdated: ((CGSize) -> Void)? = nil) {
        self.viewModel = viewModel
        self.contentSizeUpdated = contentSizeUpdated

        tiers = viewModel.displayedProducts

        // Switch to the previously selected options if available
        let displayProduct = [viewModel.continuePurchasing, viewModel.initialProduct].compactMap { $0 }.first

        if let displayProduct {
            let index = tiers.firstIndex(where: { $0.plan == displayProduct.plan }) ?? 0

            _currentSubscriptionPeriod = State(initialValue: displayProduct.frequency)
            _currentPage = State(initialValue: index)
        }
    }

    private var selectedProduct: IAPProductID {
        currentSubscriptionPeriod == .yearly ? selectedTier.plan.yearly : selectedTier.plan.monthly
    }

    var body: some View {
        ContentSizeGeometryReader(content: { proxy in
            VStack(spacing: 10) {
                Spacer()
                UpgradeRoundedSegmentedControl(selected: $currentSubscriptionPeriod)
                FeaturesCarousel(currentIndex: $currentPage.animation(), currentSubscriptionPeriod: $currentSubscriptionPeriod, viewModel: self.viewModel, tiers: tiers, showInlinePurchaseButton: true).environmentObject(self.viewModel)
                if !tiers.isEmpty {
                    PageIndicatorView(numberOfItems: tiers.count, currentPage: currentPage)
                        .foregroundColor(theme.primaryText01)
                }
                Spacer()
            }
        }, contentSizeUpdated: contentSizeUpdated)
    }
}

struct UpgradePrompt_Previews: PreviewProvider {
    static var previews: some View {
        UpgradePrompt(viewModel: PlusLandingViewModel(source: .login))
    }
}
