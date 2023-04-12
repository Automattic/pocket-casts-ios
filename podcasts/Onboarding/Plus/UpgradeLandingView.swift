import SwiftUI

struct UpgradeLandingView: View {
    @EnvironmentObject var viewModel: PlusLandingViewModel

    private let tiers: [UpgradeTier] = [.plus, .patron]

    @State private var currentPage: Int = 0

    @State private var displayPrice: DisplayPrice = .yearly

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ZStack {

                if currentPage == 0 {
                    tiers[0].background
                        .transition(.opacity.animation(currentPage == 0 ? .easeIn : .easeOut))
                        .ignoresSafeArea()
                } else {
                    tiers[1].background
                        .transition(.opacity.animation(currentPage == 0 ? .easeIn : .easeOut))
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    ScrollViewIfNeeded {
                        VStack(spacing: 0) {


                            PlusLabel(currentPage == 0 ? L10n.plusMarketingTitle : L10n.patronCallout, for: .title2)
                                .minimumScaleFactor(0.5)
                                .lineLimit(2)
                                .padding(.bottom, 16)
                                .padding(.horizontal, 32)

                            UpgradeRoundedSegmentedControl(selected: $displayPrice)
                                .padding(.bottom, 24)

                            FeaturesCarousel(currentIndex: $currentPage.animation(), currentPrice: $displayPrice, tiers: tiers)

                            PageIndicator(numberOfItems: tiers.count, currentPage: currentPage)
                            .padding(.top, 27)
                        }
                    }
                }
            }
        }
        .background(Color(hex: "121212"))
    }

    var topBar: some View {
        HStack(spacing: 0) {
            Rectangle()
                .foregroundColor(.clear)
                .frame(height: 44)
            Button(viewModel.source == .upsell ? L10n.eoyNotNow : L10n.plusSkip) {
                viewModel.dismissTapped()
            }
            .foregroundColor(.white)
            .font(style: .body, weight: .medium)
            .padding(.trailing)
        }
    }

    enum DisplayPrice {
        case yearly, monthly
    }
}

// MARK: - Feature Carousel

struct FeaturesCarousel: View {
    let currentIndex: Binding<Int>

    let currentPrice: Binding<UpgradeLandingView.DisplayPrice>

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
        .carouselPeekAmount(.constant(Constants.peekAmount))
        .carouselItemSpacing(Constants.spacing)
        .frame(height: calculatedCardHeight)
    }

    private enum Constants {
        static let peekAmount: Double = 20
        static let spacing: Double = UIDevice.current.isiPad() ? 150 : 30
    }
}

// MARK: - Available plans

struct UpgradeTier: Identifiable {
    let tier: Tier
    let iconName: String
    let title: String
    let plan: PlusPurchaseModal.Plan
    let description: String
    let buttonLabel: String
    let buttonColor: Color
    let buttonForegroundColor: Color
    let features: [TierFeature]
    let background: AnyView

    var id: String {
        tier.rawValue
    }

    enum Tier: String {
        case plus, patron
    }

    struct TierFeature: Hashable {
        let iconName: String
        let title: String
    }
}

extension UpgradeTier {
    static var plus: UpgradeTier {
        UpgradeTier(tier: .plus, iconName: "plusGold", title: "Plus", plan: .plus, description: L10n.accountDetailsPlusTitle, buttonLabel: L10n.plusSubscribeTo, buttonColor: Color(hex: "FFD846"), buttonForegroundColor: Color.plusButtonFilledTextColor, features: [
            TierFeature(iconName: "plus-feature-desktop", title: L10n.plusMarketingDesktopAppsTitle),
            TierFeature(iconName: "plus-feature-folders", title: L10n.folders),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimitFormat(10)),
            TierFeature(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
            TierFeature(iconName: "plus-feature-extra", title: L10n.plusFeatureThemesIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
        ],
        background: AnyView(LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "D4B43A"), Color(hex: "FFDE64")]), startPoint: .topLeading, endPoint: .bottomTrailing)))
    }

    static var patron: UpgradeTier {
        UpgradeTier(tier: .patron, iconName: "patron-heart", title: "Patron", plan: .patron, description: L10n.patronDescription, buttonLabel: L10n.patronSubscribeTo, buttonColor: Color(hex: "6046F5"), buttonForegroundColor: .white, features: [
            TierFeature(iconName: "patron-everything", title: "Everything in Plus"),
            TierFeature(iconName: "patron-early-access", title: L10n.patronFeatureEarlyAccess),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimitFormat(50)),
            TierFeature(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            TierFeature(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)

        ],
        background: AnyView(LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "9583F8"), Color(hex: "503ACC")]), startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}

// MARK: - Segmented Control

struct UpgradeRoundedSegmentedControl: View {
    @Binding private var selected: UpgradeLandingView.DisplayPrice

    init(selected: Binding<UpgradeLandingView.DisplayPrice>) {
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
            .padding(.all, 4)

            Button(L10n.monthly) {
                withAnimation {
                    selected = .monthly
                }
            }
            .buttonStyle(UpgradeSegmentedControlButtonStyle(isSelected: selected == .monthly))
            .padding(.all, 4)
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

    let currentPrice: Binding<UpgradeLandingView.DisplayPrice>

    var body: some View {
        VStack() {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(tier.iconName)
                        .padding(.leading, 8)
                    Text(tier.title)
                        .foregroundColor(.white)
                        .font(style: .subheadline, weight: .medium)
                        .padding(.trailing, 8)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                }
                .background(.black)
                .cornerRadius(800)
                .padding(.bottom, 10)

                HStack() {
                    Text(viewModel.pricingInfo.products.first(where: { $0.identifier.rawValue == (currentPrice.wrappedValue == .yearly ? tier.plan.yearlyIdentifier : tier.plan.monthlyIdentifier) })?.rawPrice ?? "?")
                        .font(style: .largeTitle, weight: .bold)
                    Text("/\(currentPrice.wrappedValue == .yearly ? L10n.year : L10n.month)")
                        .font(style: .headline, weight: .bold)
                        .opacity(0.6)
                        .padding(.top, 6)
                }
                .padding(.bottom, 8)

                Text(tier.description)
                    .font(style: .caption2, weight: .semibold)
                    .opacity(0.64)
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
                        }
                    }
                }
                .padding(.bottom, 24)

                Button(tier.buttonLabel) {
                    viewModel.unlockTapped(plan: tier.plan)
                }
                .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: tier.plan))
            }
            .padding(.all, 24)

        }
        .background(.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.01), radius: 10, x: 0, y: 24)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 14)
        .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 6)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 0)
    }
}

struct PageIndicator: View {
    let numberOfItems: Int

    let currentPage: Int

    var body: some View {
        HStack {
            ForEach(0 ..< numberOfItems, id: \.self) { itemIndex in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.white)
                    .opacity(itemIndex == currentPage ? 1 : 0.5)
            }
        }
    }
}

struct UpgradeLandingView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeLandingView().environmentObject(PlusLandingViewModel(source: .login))
    }
}

extension PlusPurchaseModal.Plan {
    var yearlyIdentifier: String? {
        products.first(where: { $0.rawValue.contains("yearly") })?.rawValue
    }

    var monthlyIdentifier: String? {
        products.first(where: { $0.rawValue.contains("month") })?.rawValue
    }
}
