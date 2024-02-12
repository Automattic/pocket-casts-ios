import Foundation
import SwiftUI
import PocketCastsServer

struct UpgradeTier: Identifiable {
    let tier: SubscriptionTier
    let iconName: String
    let title: String
    let plan: Plan
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
            TierFeature(iconName: "plus-feature-folders", title: L10n.plusMarketingFoldersAndBookmarksTitle),
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
            TierFeature(iconName: "plus-feature-cloud", title: L10n.patronCloudStorageLimit),
            TierFeature(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            TierFeature(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)

        ],
        background: RadialGradient(colors: [Color(hex: "503ACC").opacity(0.8), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }
}

// MARK: - Upgrade card

struct UpgradeCard: View {
    @EnvironmentObject var viewModel: PlusLandingViewModel

    @EnvironmentObject var theme: Theme

    let tier: UpgradeTier

    let currentPrice: Binding<PlanFrequency>

    let subscriptionInfo: PlusPricingInfoModel.PlusProductPricingInfo?

    let showPurchaseButton: Bool

    @State var calculatedCardHeight: CGFloat?

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                if let subscriptionInfo {
                    SubscriptionPriceAndOfferView(product: subscriptionInfo, mainTextColor: theme.primaryText01, secondaryTextColor: theme.primaryText02)
                } else {
                    SubscriptionBadge(tier: tier.tier)
                        .padding(.bottom, 12)
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 16) {
                            Image(feature.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(theme.primaryText01)
                                .frame(width: 16, height: 16)
                            Text(feature.title)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(theme.primaryText01)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    termsAndConditions
                        .font(style: .footnote).fixedSize(horizontal: false, vertical: true)
                        .tint(theme.primaryText01)
                        .opacity(0.64)
                    if showPurchaseButton {
                        purchaseButton
                    }
                }
                .padding(.bottom, 0)
            }
            .padding(24)

        }
        .background(theme.primaryUi01)
        .cornerRadius(24)
        .shadow(color: theme.primaryText01.opacity(0.01), radius: 10, x: 0, y: 24)
        .shadow(color: theme.primaryText01.opacity(0.05), radius: 8, x: 0, y: 14)
        .shadow(color: theme.primaryText01.opacity(0.09), radius: 6, x: 0, y: 6)
        .shadow(color: theme.primaryText01.opacity(0.1), radius: 3, x: 0, y: 2)
        .shadow(color: theme.primaryText01.opacity(0.1), radius: 0, x: 0, y: 0)
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
        .foregroundColor(theme.primaryText01)
    }

    @ViewBuilder
    var purchaseButton: some View {
        let hasError = Binding<Bool>(
            get: { self.viewModel.state == .failed },
            set: { _ in }
        )
        let isLoading = (viewModel.state == .purchasing) || (viewModel.priceAvailability == .loading)
        Button(action: {
            viewModel.unlockTapped(.init(plan: tier.plan, frequency: currentPrice.wrappedValue))
        }, label: {
            VStack {
                Text(tier.buttonLabel)
            }
            .transition(.opacity)
            .id("plus_price" + tier.title)
        })
        .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: tier.plan))
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
