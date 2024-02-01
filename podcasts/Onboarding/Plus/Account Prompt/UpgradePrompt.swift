import SwiftUI
import PocketCastsServer

struct UpgradePrompt: View {
    @ObservedObject var viewModel: PlusLandingViewModel
    
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
        GeometryReader { reader in
                VStack(spacing: 0) {
                    Spacer()

                    PlusLabel(selectedTier.header, for: .title2)
                        .transition(.opacity)
                        .id("plus_title" + selectedTier.header)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 32)
                    UpgradeRoundedSegmentedControl(selected: $currentSubscriptionPeriod)
                        .padding(.bottom, 24)

                    FeaturesCarousel(currentIndex: $currentPage.animation(), currentSubscriptionPeriod: $currentSubscriptionPeriod, viewModel: self.viewModel, tiers: tiers)

                    if !tiers.isEmpty {
                        PageIndicatorView(numberOfItems: tiers.count, currentPage: currentPage)
                            .foregroundColor(.white)
                            .padding(.top, 27)
                    }

                    Spacer()

                    purchaseButton
                }                                
        }
    }

    @ViewBuilder
    var purchaseButton: some View {
        let hasError = Binding<Bool>(
            get: { self.viewModel.state == .failed },
            set: { _ in }
        )
        let isLoading = (viewModel.state == .purchasing) || (viewModel.priceAvailability == .loading)
        Button(action: {
            viewModel.unlockTapped(.init(plan: selectedTier.plan, frequency: currentSubscriptionPeriod))
        }, label: {
            VStack {
                Text(selectedTier.buttonLabel)
            }
            .transition(.opacity)
            .id("plus_price" + selectedTier.title)
        })
        .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: selectedTier.plan))
        .padding(.horizontal, 20)
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

struct UpgradePrompt_Previews: PreviewProvider {
    static var previews: some View {
        UpgradePrompt(viewModel: PlusLandingViewModel(source: .login))
    }
}
