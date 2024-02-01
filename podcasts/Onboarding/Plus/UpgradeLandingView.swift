import SwiftUI
import PocketCastsServer

struct UpgradeLandingView: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    private let tiers: [UpgradeTier]
    private var selectedTier: UpgradeTier {
        tiers[currentPage]
    }

    @State private var contentIsScrollable = false

    @State private var purchaseButtonHeight: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var currentSubscriptionPeriod: PlanFrequency = .yearly

    init(viewModel: PlusLandingViewModel) {
        self.viewModel = viewModel

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

    /// If this device has a small screen
    private var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667
    }

    /// If this device has a bottom safe area
    private var hasBottomSafeArea: Bool {
        !UIDevice.current.isiPad() && safeAreaBottomHeight > 0
    }

    private var safeAreaBottomHeight: CGFloat {
        (SceneHelper.connectedScene()?.windows.first(where: \.isKeyWindow)?.safeAreaInsets.bottom ?? 0)
    }

    var body: some View {
        ZStack {
            ForEach(tiers) { tier in
                tier.background
                    .opacity(selectedTier.id == tier.id ? 1 : 0)
                    .ignoresSafeArea()
            }

            ZStack {
                VStack(spacing: 0) {
                    topBar

                    GeometryReader { reader in
                        ScrollView {
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

                                if tiers.count > 1 && !isSmallScreen && !contentIsScrollable {
                                    PageIndicatorView(numberOfItems: tiers.count, currentPage: currentPage)
                                        .foregroundColor(.white)
                                        .padding(.top, 27)
                                }

                                Spacer()

                                // Add an invisible rectangle to fill the purchase button size, so scroll and vertical centering works fine
                                Rectangle()
                                    .frame(height: purchaseButtonHeight)
                                    .opacity(0)
                                    .disabled(true)
                            }
                            .frame(minHeight: reader.size.height)
                            .modifier(ViewHeightKey())
                        }
                        .onPreferenceChange(ViewHeightKey.self) {
                            if $0 > reader.size.height {
                                contentIsScrollable = true
                            }
                        }
                    }
                }

                if contentIsScrollable {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer()

                            LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                .opacity(0.8)
                                .allowsHitTesting(false)
                                .frame(height: purchaseButtonHeight + safeAreaBottomHeight + 10)
                        }
                    }
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    Spacer()

                    purchaseButton
                        .overlay {
                            GeometryReader { reader in
                                Action {
                                    purchaseButtonHeight = reader.size.height
                                }
                            }
                        }
                }
            }

        }
        .background(Color.plusBackgroundColor)
    }

    var topBar: some View {
        HStack(spacing: 0) {
            Spacer()
            Button(viewModel.source == .upsell ? L10n.eoyNotNow : L10n.plusSkip) {
                viewModel.dismissTapped()
            }
            .foregroundColor(.white)
            .font(style: .body, weight: .medium)
            .padding()
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
        .padding(.bottom, hasBottomSafeArea ? 0 : 16)
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


// MARK: - View Height

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

extension ViewHeightKey: ViewModifier {
    func body(content: Content) -> some View {
        return content.background(GeometryReader { proxy in
            Color.clear.preference(key: Self.self, value: proxy.size.height)
        })
    }
}

struct UpgradeLandingView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeLandingView(viewModel: PlusLandingViewModel(source: .login))
    }
}
