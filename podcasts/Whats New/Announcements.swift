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
                AnnouncementFlow.shared.isShowingAutoplayOption = true

                NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
            },
            isEnabled: true
        ),

        // Bookmarks Early Access: Beta
        // Show only in TestFlight, for Plus and Patron
        .init(
            version: "7.52",
            header: AnyView(BookmarksWhatsNewHeader()),
            title: L10n.announcementBookmarksTitleBeta,
            message: L10n.announcementBookmarksDescription,
            buttonTitle: bookmarksViewModel.enableButtonTitle,
            action: {
                bookmarksViewModel.enableAction()
            },
            displayTier: bookmarksViewModel.displayTier,
            isEnabled: bookmarksViewModel.isEarlyAccessBetaAnnouncementEnabled
        ),

        // Bookmarks Early Access: Release
        // Show when not in beta, for Patron only
        .init(
            version: "7.52",
            header: AnyView(BookmarksWhatsNewHeader().onAppear {
                // Record when someone sees the full announcement while in early access so we don't show it again to them when we move to full release.
                bookmarksViewModel.markAsSeen()
            }),
            title: L10n.announcementBookmarksTitle,
            message: L10n.announcementBookmarksDescription,
            buttonTitle: bookmarksViewModel.enableButtonTitle,
            action: {
                bookmarksViewModel.enableAction()
            },
            displayTier: bookmarksViewModel.displayTier,
            isEnabled: bookmarksViewModel.isEarlyAccessAnnouncementEnabled
        ),

        // Bookmarks: Full Release
        // Show for everyone, except those who saw the `Early Access: Release` announcement
        .init(
            version: "99.99",
            header: AnyView(BookmarksWhatsNewHeader()),
            title: L10n.announcementBookmarksTitle,
            message: L10n.announcementBookmarksDescription,
            buttonTitle: bookmarksViewModel.upgradeOrEnableButtonTitle,
            action: {
                bookmarksViewModel.enableAction()
            },
            displayTier: bookmarksViewModel.displayTier,
            isEnabled: bookmarksViewModel.isReleaseAnnouncementEnabled
        )
    ]
}

class AnnouncementFlow {
    static let shared = AnnouncementFlow()

    var isShowingAutoplayOption = false
    var bookmarksFlow: BookmarksFlow = .none

    enum BookmarksFlow {
        case none, player, profile
    }
}
