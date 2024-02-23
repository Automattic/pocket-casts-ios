import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct Announcements {
    private static let bookmarksViewModel = BookmarkAnnouncementViewModel()

    // Order is important.
    // In the case a user migrates to, let's say, 7.10 to 7.15 and
    // there were two announcements, the last one will be picked.
    var announcements: [WhatsNew.Announcement] = [
        // Autoplay
        .init(
            version: "7.43",
            header: AnyView(AutoplayWhatsNewHeader()),
            title: L10n.announcementAutoplayTitle,
            message: L10n.announcementAutoplayDescription,
            buttonTitle: L10n.enableItNow,
            action: {
                AnnouncementFlow.current = .autoPlay

                NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
            },
            isEnabled: true
        ),

        // Bookmarks: Full Release
        // Show for everyone, except those who saw the `Early Access: Release` announcement
        .init(
            version: "7.53",
            header: AnyView(BookmarksWhatsNewHeader()),
            title: L10n.announcementBookmarksTitle,
            message: L10n.announcementBookmarksDescription,
            buttonTitle: bookmarksViewModel.upgradeOrEnableButtonTitle,
            action: {
                bookmarksViewModel.enableAction()
            },
            displayTier: bookmarksViewModel.displayTier,
            isEnabled: bookmarksViewModel.isReleaseAnnouncementEnabled
        ),

        // Slumber Studios partnership
        .init(
            version: "7.57",
            header: AnyView(SlumberWhatsNewHeader()),
            title: "",
            message: "",
            buttonTitle: "",
            action: {},
            isEnabled: FeatureFlag.slumber.enabled,
            fullModal: true,
            customBody: AnyView(SlumberCustomBody())
        ),

        // Deselect Chapters
//        .init(
//            version: "7.59",
//            header: AnyView(Image("deselect_chapters")),
//            title: L10n.skipChapters,
//            message: L10n.announcementDeselectChaptersPatron,
//            buttonTitle: L10n.gotIt,
//            action: {
//                SceneHelper.rootViewController()?.dismiss(animated: true)
//            },
//            isEnabled: FeatureFlag.deselectChapters.enabled
//                       && PaidFeature.deselectChapters.tier == .patron
//                       && SubscriptionHelper.activeTier == .patron,
//            fullModal: true
//        ),

        .init(
            version: "7.59",
            header: AnyView(Image("deselect_chapters")),
            title: L10n.skipChapters,
            message: SubscriptionHelper.hasActiveSubscription() ? L10n.announcementDeselectChaptersPlus : L10n.announcementDeselectChaptersFree,
            buttonTitle: SubscriptionHelper.hasActiveSubscription() ? L10n.gotIt : L10n.upgradeToPlus,
            action: {
                SceneHelper.rootViewController()?.dismiss(animated: true) {
                    if !SubscriptionHelper.hasActiveSubscription(), let rootViewController = SceneHelper.rootViewController() {
                        PaidFeature.deselectChapters.presentUpgradeController(from: rootViewController, source: "deselect_chapters_whats_new")
                    }
                }
            },
            isEnabled: FeatureFlag.deselectChapters.enabled
                       && PaidFeature.deselectChapters.tier == .plus
                       && SubscriptionHelper.activeTier < .patron,
            fullModal: true
        )
    ]
}

// MARK: - AnnouncementFlow

enum AnnouncementFlow {
    static var current: Self = .none

    /// No active flow
    case none

    /// Show the autoplay settings
    case autoPlay

    /// Show the player and highlight the Add Bookmark item
    case bookmarksPlayer

    /// Show the headphone controls action for Bookmarks
    case bookmarksProfile
}
