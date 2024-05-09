import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct Announcements {
    private static let bookmarksViewModel = BookmarkAnnouncementViewModel()
    private static let chaptersViewModel = DeselectChaptersAnnouncementViewModel()

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

        // Deselect Chapters (Patron announcement)
        .init(
            version: "7.60",
            header: AnyView(Image("deselect_chapters")),
            title: L10n.skipChapters,
            message: L10n.announcementDeselectChaptersPatron,
            buttonTitle: L10n.gotIt,
            action: {
                SceneHelper.rootViewController()?.dismiss(animated: true)
            },
            isEnabled: chaptersViewModel.isPatronAnnouncementEnabled,
            fullModal: true
        ),

        // Deselect Chapters (Plus on TestFlight announcement)
        .init(
            version: "7.60",
            header: AnyView(Image("deselect_chapters")),
            title: L10n.skipChapters,
            message: chaptersViewModel.plusFreeMessage,
            buttonTitle: chaptersViewModel.plusFreeButtonTitle,
            action: {
                chaptersViewModel.buttonAction()
            },
            isEnabled: chaptersViewModel.isPlusAnnouncementEnabled,
            fullModal: true
        ),

        // Deselect Chapters (Non-Patron general public announcement)
//        .init(
//            version: "7.61",
//            header: AnyView(Image("deselect_chapters")),
//            title: L10n.skipChapters,
//            message: chaptersViewModel.plusFreeMessage,
//            buttonTitle: chaptersViewModel.plusFreeButtonTitle,
//            action: {
//                chaptersViewModel.buttonAction()
//            },
//            isEnabled: chaptersViewModel.isPlusFreeAnnouncementEnabled,
//            fullModal: true
//        )
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
