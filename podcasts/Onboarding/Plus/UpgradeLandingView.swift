import SwiftUI

struct UpgradeLandingView: View {
    var body: some View {
        ZStack {

            LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "D4B43A"), Color(hex: "FFDE64")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollViewIfNeeded {
                VStack(spacing: 0) {
                    PlusLabel(L10n.plusMarketingTitle, for: .title2)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 32)

                    UpgradeRoundedSegmentedControl()
                        .padding(.bottom, 24)

                    UpgradeCard(tier: PlusTier())
                }
            }
        }
    }
}

protocol UpgradeTier {
    var iconName: String { get }
    var title: String { get }
    var price: String { get }
    var description: String { get }
    var features: [TierFeature] { get }
}

struct TierFeature: Hashable {
    let iconName: String
    let title: String
}

struct PlusTier: UpgradeTier {
    let iconName = "plus_gold"
    let title = "Plus"
    let price = "$39.99"
    let description = L10n.accountDetailsPlusTitle
    let features = [
        TierFeature(iconName: "plus-feature-desktop", title: L10n.plusMarketingDesktopAppsTitle),
        TierFeature(iconName: "plus-feature-folders", title: L10n.folders),
        TierFeature(iconName: "plus-feature-cloud", title: L10n.plusCloudStorageLimitFormat(10)),
        TierFeature(iconName: "plus-feature-watch", title: L10n.plusMarketingWatchPlaybackTitle),
        TierFeature(iconName: "plus-feature-extra", title: L10n.plusFeatureThemesIcons),
        TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
    ]
}

struct UpgradeRoundedSegmentedControl: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Text(L10n.yearly)
                    .font(style: .subheadline, weight: .medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .background(.white)
            .cornerRadius(24)
            .padding(.all, 4)

            ZStack {
                Text(L10n.monthly)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .cornerRadius(24)
            .padding(.all, 4)
        }
        .background(.white.opacity(0.16))
        .cornerRadius(24)
    }
}

struct UpgradeCard: View {
    let tier: UpgradeTier

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
                    Text(tier.price)
                        .font(style: .largeTitle, weight: .bold)
                    Text("/\(L10n.year)")
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

                Button("Subscribe to Plus") {

                }
                .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, background: Color(hex: "FFD846")))
            }
            .padding(.all, 24)

        }
        .background(.white)
        .cornerRadius(24)
        .padding(.leading, 40)
        .padding(.trailing, 40)
        .shadow(color: .black.opacity(0.01), radius: 10, x: 0, y: 24)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 14)
        .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 6)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 0)
    }
}

struct UpgradeLandingView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeLandingView()
    }
}
