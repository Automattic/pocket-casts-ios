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
            title: L10n.announcementSlumberTitle,
            message: (SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberPlusDescription("**\(Settings.slumberPromoCode ?? "")**") : L10n.announcementSlumberNonPlusDescription).replacingOccurrences(of: L10n.announcementSlumberPlusDescriptionLearnMore, with: "[\(L10n.announcementSlumberPlusDescriptionLearnMore)](https://slumberstudios.com)"),
            buttonTitle: SubscriptionHelper.hasActiveSubscription() ? L10n.announcementSlumberRedeem : L10n.plusSubscribeTo,
            action: {
                let promptViewModel = SlumberUpgradeViewModel()
                promptViewModel.showUpgrade()
            },
            isEnabled: true,
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
