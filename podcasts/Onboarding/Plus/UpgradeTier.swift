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
        UpgradeTier(tier: .plus, iconName: "plusGold", title: "Plus", plan: .plus, header: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.upgradeAccountTitle : L10n.plusMarketingTitle, description: L10n.accountDetailsPlusTitle, buttonLabel: L10n.plusSubscribeTo, buttonForegroundColor: Color.plusButtonFilledTextColor, monthlyFeatures: plusMonthlyFeatures, yearlyFeatures: plusYearlyFeatures,
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
        else {
            return [
                bannerAdsFeature,
                generatedTranscriptsFeature,
                foldersFeature,
                upNextShuffleFeature,
                bookmarksFeature,
                deselectChaptersFeature,
                cloudFeature,
                watchFeature,
                extraThemesIconsFeature,
                libroFm
            ].compactMap { $0 }
        }
    }

    static var plusYearlyFeatures: [UpgradeTier.TierFeature] {
        if FeatureFlag.newOnboardingUpgrade.enabled {
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
        else {
            return [
                bannerAdsFeature,
                generatedTranscriptsFeature,
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
            TierFeature(iconName: "patron-everything", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingAllPlusFeatures : L10n.patronFeatureEverythingInPlus),
            TierFeature(iconName: "patron-early-access", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingEarlyAccess : L10n.patronFeatureEarlyAccess),
            TierFeature(iconName: "plus-feature-cloud", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingCloudStorage(Settings.patronCloudStorageLimit.localized()) : L10n.patronCloudStorageLimit),
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
        TierFeature(iconName: "plus-feature-folders", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingFolders : L10n.plusMarketingFoldersTitle)
    }

    static var upNextShuffleFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-up-next-shuffle", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingUpNextShuffle : L10n.plusMarketingUpNextShuffle)
    }

    static var bookmarksFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-bookmarks", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingBookmarks : L10n.plusMarketingBookmarksTitle)
    }

    static var deselectChaptersFeature: UpgradeTier.TierFeature? {
        PaidFeature.deselectChapters.tier == .plus ? TierFeature(iconName: "rounded-selected", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingSkipChapters : L10n.skipChapters) : nil
    }

    static var cloudFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-cloud", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingCloudStorage(Settings.plusCloudStorageLimit.localized()) : L10n.plusCloudStorageLimit)
    }

    static var watchFeature: UpgradeTier.TierFeature {
        TierFeature(iconName: "plus-feature-watch", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingWatchPlayback: L10n.plusMarketingWatchPlaybackTitle)
    }

    static var slumberOrUndyingGratitude: TierFeature {
        FeatureFlag.slumber.enabled ? slumber : loveFeature
    }

    static var extraThemesIconsFeature: TierFeature {
        TierFeature(iconName: "plus-feature-extra", title: FeatureFlag.newOnboardingUpgrade.enabled ? L10n.featureMarketingExtraThemesIcons : L10n.plusFeatureThemesIcons )
    }

    static var loveFeature: TierFeature {
        TierFeature(iconName: "plus-feature-love", title: L10n.plusFeatureGratitude)
    }

    static var slumber: TierFeature {
        let message: String
        if FeatureFlag.newOnboardingUpgrade.enabled {
            message = L10n.featureMarketingSlumber.slumberStudiosWithUrl
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
