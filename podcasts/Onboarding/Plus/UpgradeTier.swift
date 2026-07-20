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
        UpgradeTier(tier: .plus, iconName: "plusGold", title: "Plus", plan: .plus, header: L10n.upgradeAccountTitle, description: L10n.accountDetailsPlusTitle, buttonLabel: L10n.plusSubscribeTo, buttonForegroundColor: Color.plusButtonFilledTextColor, monthlyFeatures: plusMonthlyFeatures, yearlyFeatures: plusYearlyFeatures,
                    background: RadialGradient(colors: [Color(hex: "FFDE64").opacity(0.5), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }

    static var patron: UpgradeTier {
        UpgradeTier(tier: .patron, iconName: "patron-heart", title: "Patron", plan: .patron, header: L10n.patronCallout, description: L10n.patronDescription, buttonLabel: L10n.patronSubscribeTo, buttonForegroundColor: .white, monthlyFeatures: patronFeatures, yearlyFeatures: patronFeatures,
                    background: RadialGradient(colors: [Color(hex: "503ACC").opacity(0.8), Color(hex: "121212")], center: .leading, startRadius: 0, endRadius: 500))
    }

    static var plusMonthlyFeatures: [UpgradeTier.TierFeature] {
        return [
            bannerAdsFeature,
            generatedTranscriptsFeature,
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

    static var plusYearlyFeatures: [UpgradeTier.TierFeature] {
        return [
            bannerAdsFeature,
            generatedTranscriptsFeature,
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

    static var patronFeatures: [UpgradeTier.TierFeature] {
        [
            TierFeature(iconName: "patron-everything", title: L10n.featureMarketingAllPlusFeatures),
            TierFeature(iconName: "patron-early-access", title: L10n.featureMarketingEarlyAccess),
            TierFeature(iconName: "plus-feature-cloud", title: L10n.featureMarketingCloudStorage(Settings.patronCloudStorageLimit.localized())),
            TierFeature(iconName: "patron-badge", title: L10n.patronFeatureProfileBadge),
            TierFeature(iconName: "patron-icons", title: L10n.patronFeatureProfileIcons),
            TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
        ].compactMap { $0 }
    }

    static var bannerAdsFeature: UpgradeTier.TierFeature? {
        (FeatureFlag.bannerAdPodcasts.enabled || FeatureFlag.bannerAdPlayer.enabled) ? .init(iconName: "unsubscribe", title: L10n.plusMarketingNoBannerAds) : nil
    }

    static var generatedTranscriptsFeature: UpgradeTier.TierFeature? {
        (FeatureFlag.generatedTranscripts.enabled) ? .init(iconName: "transcript", title: L10n.plusMarketingGeneratedTranscripts) : nil
    }

    static var foldersFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-folders", title: L10n.featureMarketingFolders)
    }

    static var upNextShuffleFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-up-next-shuffle", title: L10n.featureMarketingUpNextShuffle)
    }

    static var bookmarksFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-bookmarks", title: L10n.featureMarketingBookmarks)
    }

    static var deselectChaptersFeature: UpgradeTier.TierFeature? {
        PaidFeature.deselectChapters.tier == .plus ? TierFeature(iconName: "rounded-selected", title: L10n.featureMarketingSkipChapters) : nil
    }

    static var cloudFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-cloud", title: L10n.featureMarketingCloudStorage(Settings.plusCloudStorageLimit.localized()))
    }

    static var watchFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-watch", title: L10n.featureMarketingWatchPlayback)
    }

    static var slumberOrUndyingGratitude: TierFeature {
        FeatureFlag.slumber.enabled ? slumber : loveFeature
    }

    static var extraThemesIconsFeature: TierFeature {
        TierFeature(iconName: "plus-feature-extra", title: L10n.featureMarketingExtraThemesIcons)
    }

    static var loveFeature: TierFeature {
        TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
    }

    static var slumber: TierFeature {
        let message = L10n.featureMarketingSlumber.slumberStudiosWithUrl
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
