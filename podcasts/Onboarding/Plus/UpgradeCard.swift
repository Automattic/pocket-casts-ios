import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct UpgradeTier: Identifiable {
    let tier: SubscriptionTier
    let iconName: String
    let title: String
    let plan: Plan
    let header: String
    let description: String
    let buttonLabel: String
    let buttonForegroundColor: Color
    let monthlyFeatures: [TierFeature]
    let yearlyFeatures: [TierFeature]
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
        UpgradeTier(tier: .plus, iconName: "plusGold", title: "Plus", plan: .plus, header: L10n.plusMarketingTitle, description: L10n.accountDetailsPlusTitle, buttonLabel: L10n.plusSubscribeTo, buttonForegroundColor: Color.plusButtonFilledTextColor, monthlyFeatures: plusMonthlyFeatures, yearlyFeatures: plusYearlyFeatures,
        background: RadialGradient(colors: [Color(hex: "FFDE64").opacity(0.5), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }

    static var patron: UpgradeTier {
        UpgradeTier(tier: .patron, iconName: "patron-heart", title: "Patron", plan: .patron, header: L10n.patronCallout, description: L10n.patronDescription, buttonLabel: L10n.patronSubscribeTo, buttonForegroundColor: .white, monthlyFeatures: patronFeatures, yearlyFeatures: patronFeatures,
        background: RadialGradient(colors: [Color(hex: "503ACC").opacity(0.8), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }

    static var plusMonthlyFeatures: [UpgradeTier.TierFeature] {
        if FeatureFlag.newOnboardingUpgrade.enabled {
            return [
                bannerAdsFeature,
                foldersFeature,
                upNextShuffleFeature,
                bookmarksFeature,
                deselectChaptersFeature,
                cloudFeature,
                extraThemesIconsFeature,
                watchFeature,
                libroFm
            ].compactMap { $0 }
        }
        else {
            return [
                bannerAdsFeature,
                foldersFeature,
                upNextShuffleFeature,
                bookmarksFeature,
                deselectChaptersFeature,
                cloudFeature,
                watchFeature,
                extraThemesIconsFeature,
                loveFeature,
                libroFm
            ].compactMap { $0 }
        }
    }

    static var plusYearlyFeatures: [UpgradeTier.TierFeature] {
        if FeatureFlag.newOnboardingUpgrade.enabled {
            return [
                bannerAdsFeature,
                foldersFeature,
                upNextShuffleFeature,
                bookmarksFeature,
                deselectChaptersFeature,
                cloudFeature,
                extraThemesIconsFeature,
                watchFeature,
                slumber,
                libroFm
            ].compactMap { $0 }
        }
        else {
            return [
                bannerAdsFeature,
                foldersFeature,
                upNextShuffleFeature,
                bookmarksFeature,
                deselectChaptersFeature,
                cloudFeature,
                watchFeature,
                FeatureFlag.slumber.enabled && FeatureFlag.upgradeExperiment.enabled ? slumber : nil,
                extraThemesIconsFeature,
                FeatureFlag.upgradeExperiment.enabled ? nil : slumberOrUndyingGratitude,
                libroFm
            ].compactMap { $0 }
        }
    }

    static var patronFeatures: [UpgradeTier.TierFeature] {
        [
            TierFeature(iconName: "patron-everything", title: L10n.patronFeatureEverythingInPlus),
            TierFeature(iconName: "patron-early-access", title: L10n.patronFeatureEarlyAccess),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.patronCloudStorageLimit),
            TierFeature(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            TierFeature(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
        ].compactMap { $0 }
    }

    static var bannerAdsFeature: UpgradeTier.TierFeature? {
        FeatureFlag.bannerAds.enabled ? .init(iconName: "unsubscribe", title: L10n.plusMarketingNoBannerAds) : nil
    }

    static var foldersFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-folders", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Tidy your collection with Folders" : L10n.plusMarketingFoldersTitle)
    }

    static var upNextShuffleFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-up-next-shuffle", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Shuffle your queue" : L10n.plusMarketingUpNextShuffle)
    }

    static var bookmarksFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-bookmarks", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Keep timestamps with Bookmarks" : L10n.plusMarketingBookmarksTitle)
    }

    static var deselectChaptersFeature: UpgradeTier.TierFeature? {
        PaidFeature.deselectChapters.tier == .plus ? TierFeature(iconName: "rounded-selected", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Save time with Preselect Chapters" : L10n.skipChapters) : nil
    }

    static var cloudFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-cloud", title: FeatureFlag.newOnboardingUpgrade.enabled ? "20 GB Cloud Storage for your files" : L10n.plusCloudStorageLimit)
    }

    static var watchFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-watch", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Apps for Wear OS and Apple Watch" : L10n.plusMarketingWatchPlaybackTitle)
    }

    static var slumberOrUndyingGratitude: TierFeature {
        FeatureFlag.slumber.enabled ? slumber : loveFeature
    }

    static var extraThemesIconsFeature: TierFeature {
        TierFeature(iconName: "plus-feature-extra", title: FeatureFlag.newOnboardingUpgrade.enabled ? "Extra Themes and App Icons" : L10n.plusFeatureThemesIcons )
    }

    static var loveFeature: TierFeature {
        TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
    }

    static var slumber: TierFeature {
        let message: String
        if FeatureFlag.newOnboardingUpgrade.enabled {
            message = "1 year of content from Slumber Studios".slumberStudiosWithUrl
        } else {
            message = FeatureFlag.upgradeExperiment.enabled ? L10n.plusFeatureSlumberNew.newSlumberStudiosWithUrl : L10n.plusFeatureSlumber.slumberStudiosWithUrl
        }
        return TierFeature(iconName: "plus-feature-slumber", title: message)
    }

    private static var libroFm: TierFeature? {
        if FeatureFlag.libroFm.enabled {
            return TierFeature(iconName: "plus-feature-librofm", title: L10n.plusFeatureLibrofm.libroFmWithURL)
        }
        return nil
    }

    func update(header: String) -> Self {
        return UpgradeTier(
            tier: self.tier,
            iconName: self.iconName,
            title: self.title,
            plan: self.plan,
            header: header,
            description: self.description,
            buttonLabel: self.buttonLabel,
            buttonForegroundColor: self.buttonForegroundColor,
            monthlyFeatures: self.monthlyFeatures,
            yearlyFeatures: self.yearlyFeatures,
            background: self.background)
    }
}

// MARK: - Upgrade card

struct UpgradeCard: View {
    @EnvironmentObject var viewModel: PlusLandingViewModel

    @EnvironmentObject var theme: Theme

    @Environment(\.openURL) private var openURL

    @Environment(\.sizeCategory) private var sizeCategory

    let tier: UpgradeTier

    let currentPrice: Binding<PlanFrequency>

    let subscriptionInfo: PlusPricingInfoModel.PlusProductPricingInfo?

    let showPurchaseButton: Bool

    private var subscriptionPriceSecondaryTextColor: Color {
        if theme.activeTheme == .light {
            return Color(hex: "#6F7580")
        }
        return theme.primaryText02
    }

    private var termsAndConditionsTextColor: Color {
        if theme.activeTheme == .light {
            return Color(hex: "#6F7580")
        }
        return theme.primaryText01
    }

    private var termsAndConditionsOpacity: Double {
        if theme.activeTheme == .light {
            return 1.0
        }
        return 0.64
    }

    private var featureSpacing: CGFloat {
        max(16.0, 16.0 * ScaleFactorModifier.scaleFactor(for: sizeCategory))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                if let subscriptionInfo {
                    SubscriptionPriceAndOfferView(product: subscriptionInfo, mainTextColor: theme.primaryText01, secondaryTextColor: subscriptionPriceSecondaryTextColor)
                } else {
                    SubscriptionBadge(tier: tier.tier)
                        .padding(.bottom, 12)
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(currentPrice.wrappedValue == .monthly ? tier.monthlyFeatures : tier.yearlyFeatures, id: \.self) { feature in
                        HStack(spacing: featureSpacing) {
                            Image(feature.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleFactor(for: sizeCategory)
                                .foregroundColor(theme.primaryText01)
                                .frame(width: 16, height: 16)
                            UnderlineLinkTextView(feature.title)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(theme.primaryText01)
                                .tint(theme.primaryText01)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    termsAndConditions
                        .font(style: .footnote).fixedSize(horizontal: false, vertical: true)
                        .tint(termsAndConditionsTextColor)
                        .opacity(termsAndConditionsOpacity)
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
        .foregroundColor(termsAndConditionsTextColor)
        .environment(\.openURL, OpenURLAction { url in
            switch url.absoluteString {
            case privacyPolicy:
                viewModel.privacyPolicyTapped()
            case termsOfUse:
                viewModel.termsOfUseTapped()
            default:
                break
            }
            return .systemAction
        })
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
                Text(purchaseTitle)
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

    private var purchaseTitle: String {
        guard let subscriptionInfo = viewModel.pricingInfo(for: tier, frequency: currentPrice.wrappedValue) else {
            return tier.buttonLabel
        }

        if subscriptionInfo.offer?.type == .freeTrial {
            return L10n.freeTrialStartButton
        }

        return tier.buttonLabel
    }
}
