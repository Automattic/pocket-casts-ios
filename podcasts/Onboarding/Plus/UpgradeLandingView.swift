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
    @State private var displayPrice: Constants.PlanFrequency = .yearly

    init(viewModel: PlusLandingViewModel) {
        self.viewModel = viewModel

        tiers = viewModel.displayedProducts

        // Switch to the previously selected options if available
        let displayProduct = [viewModel.continuePurchasing, viewModel.initialProduct].compactMap { $0 }.first

        if let displayProduct {
            let index = tiers.firstIndex(where: { $0.plan == displayProduct.plan }) ?? 0

            _displayPrice = State(initialValue: displayProduct.frequency)
            _currentPage = State(initialValue: index)
        }
    }

    private var selectedProduct: Constants.IapProducts {
        displayPrice == .yearly ? selectedTier.plan.yearly : selectedTier.plan.monthly
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

                                UpgradeRoundedSegmentedControl(selected: $displayPrice)
                                    .padding(.bottom, 24)

                                FeaturesCarousel(currentIndex: $currentPage.animation(), currentPrice: $displayPrice, tiers: tiers)

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
            viewModel.unlockTapped(.init(plan: selectedTier.plan, frequency: displayPrice))
        }, label: {
            VStack {
                Text(viewModel.purchaseTitle(for: selectedTier, frequency: $displayPrice.wrappedValue))
                Text(viewModel.purchaseSubtitle(for: selectedTier, frequency: $displayPrice.wrappedValue))
                    .font(style: .subheadline)
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

// MARK: - Feature Carousel

private struct FeaturesCarousel: View {
    let currentIndex: Binding<Int>

    let currentPrice: Binding<Constants.PlanFrequency>

    let tiers: [UpgradeTier]

    @State var calculatedCardHeight: CGFloat?

    var body: some View {
        // Store the calculated card heights
        var cardHeights: [CGFloat] = []

        HorizontalCarousel(currentIndex: currentIndex, items: tiers) {
            UpgradeCard(tier: $0, currentPrice: currentPrice)
                .overlay(
                    // Calculate the height of the card after it's been laid out
                    GeometryReader { proxy in
                        Action {
                            // Add the calculated height to the array
                            cardHeights.append(proxy.size.height)

                            // Determine the max height only once we've calculated all the heights
                            if cardHeights.count == tiers.count {
                                calculatedCardHeight = cardHeights.max()

                                // Reset the card heights so any view changes won't use old data
                                cardHeights = []
                            }
                        }
                    }
                )
        }
        .carouselPeekAmount(.constant(tiers.count > 1 ? ViewConstants.peekAmount : 0))
        .carouselItemSpacing(ViewConstants.spacing)
        .carouselScrollEnabled(tiers.count > 1)
        .frame(height: calculatedCardHeight)
        .padding(.leading, 30)
    }

    private enum ViewConstants {
        static let peekAmount: Double = 20
        static let spacing: Double = 30
    }
}

// MARK: - Available plans

struct UpgradeTier: Identifiable {
    let tier: SubscriptionTier
    let iconName: String
    let title: String
    let plan: Constants.Plan
    let header: String
    let description: String
    let buttonLabel: String
    let buttonForegroundColor: Color
    let features: [TierFeature]
    let background: RadialGradient

    var id: String {
        tier.rawValue
    }

    struct TierFeature: Hashable {
        let iconName: String
        let title: String
    }
}

extension UpgradeTier {
    static var plus: UpgradeTier {
        UpgradeTier(tier: .plus, iconName: "plusGold", title: "Plus", plan: .plus, header: L10n.plusMarketingTitle, description: L10n.accountDetailsPlusTitle, buttonLabel: L10n.plusSubscribeTo, buttonForegroundColor: Color.plusButtonFilledTextColor, features: [
            TierFeature(iconName: "plus-feature-desktop", title: L10n.plusMarketingDesktopAppsTitle),
            TierFeature(iconName: "plus-feature-folders", title: L10n.folders),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimit),
            TierFeature(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
            TierFeature(iconName: "plus-feature-extra", title: L10n.plusFeatureThemesIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
        ],
                    background: RadialGradient(colors: [Color(hex: "FFDE64").opacity(0.5), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }

    static var patron: UpgradeTier {
        UpgradeTier(tier: .patron, iconName: "patron-heart", title: "Patron", plan: .patron, header: L10n.patronCallout, description: L10n.patronDescription, buttonLabel: L10n.patronSubscribeTo, buttonForegroundColor: .white, features: [
            TierFeature(iconName: "patron-everything", title: L10n.patronFeatureEverythingInPlus),
            TierFeature(iconName: "patron-early-access", title: L10n.patronFeatureEarlyAccess),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimitFormat(50)),
            TierFeature(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            TierFeature(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)

        ],
        background: RadialGradient(colors: [Color(hex: "503ACC").opacity(0.8), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }
}

// MARK: - Segmented Control

struct UpgradeRoundedSegmentedControl: View {
    @Binding private var selected: Constants.PlanFrequency

    init(selected: Binding<Constants.PlanFrequency>) {
        self._selected = selected
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(L10n.yearly) {
                withAnimation {
                    selected = .yearly
                }
            }
            .buttonStyle(UpgradeSegmentedControlButtonStyle(isSelected: selected == .yearly))
            .padding(4)

            Button(L10n.monthly) {
                withAnimation {
                    selected = .monthly
                }
            }
            .buttonStyle(UpgradeSegmentedControlButtonStyle(isSelected: selected == .monthly))
            .padding(4)
        }
        .background(.white.opacity(0.16))
        .cornerRadius(24)
    }
}

struct UpgradeSegmentedControlButtonStyle: ButtonStyle {
    let isSelected: Bool

    init(isSelected: Bool = true) {
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? .white : configuration.isPressed ? .white.opacity(0.1) : .clear
            )
            .font(style: .subheadline, weight: .medium)
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(100)
            .contentShape(Rectangle())
    }
}

// MARK: - Upgrade card

struct UpgradeCard: View {
    @EnvironmentObject var viewModel: PlusLandingViewModel

    let tier: UpgradeTier

    let currentPrice: Binding<Constants.PlanFrequency>

    @State var calculatedCardHeight: CGFloat?

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                SubscriptionBadge(tier: tier.tier)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 16) {
                            Image(feature.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.black)
                                .frame(width: 16, height: 16)
                            Text(feature.title)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    termsAndConditions
                        .font(style: .footnote).fixedSize(horizontal: false, vertical: true)
                        .tint(.black)
                        .opacity(0.64)
                }
                .padding(.bottom, 0)
            }
            .padding(24)

        }
        .background(.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.01), radius: 10, x: 0, y: 24)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 14)
        .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 6)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 0)
    }

    @ViewBuilder
    var termsAndConditions: some View {
        let purchaseTerms = L10n.purchaseTerms("$", "$", "$", "$").components(separatedBy: "$")

        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Group {
            Text(purchaseTerms[safe: 0] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 1] ?? "")](\(privacyPolicy))")).underline() +
            Text(purchaseTerms[safe: 2] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 3] ?? "")](\(termsOfUse))")).underline()
        }
        .foregroundColor(.black)
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
