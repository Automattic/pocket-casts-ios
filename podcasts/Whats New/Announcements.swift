import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct Announcements {
    // Order is important.
    // In the case a user migrates to, let's say, 7.10 to 7.15 and
    // there were two announcements, the last one will be picked.
    var announcements: [WhatsNew.Announcement] = [
        // Autoplay
        .init(
            version: "7.43",
            header: {
                AnyView(AutoplayWhatsNewHeader())
            },
            title: L10n.announcementAutoplayTitle,
            message: L10n.announcementAutoplayDescription,
            buttonTitle: L10n.enableItNow,
            action: {
                AnnouncementFlow.shared.isShowingAutoplayOption = true

                NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey, data: nil)
            }
        ),

        // Bookmarks Early Access: Beta
        // Show only in TestFlight, for Plus and Patron
        .init(
            version: "99.99",
            header: { AnyView(EmptyView()) },
            title: "Early Access Beta Title",
            message: "Message",
            buttonTitle: "Button",
            action: {},
            isEnabled: PaidFeature.bookmarks.inEarlyAccess && BuildEnvironment.current == .testFlight && SubscriptionHelper.activeTier > .none
        ),

        // Bookmarks Early Access: Release
        // Show when not in beta, for Patron only
        .init(
            version: "99.99",
            header: { AnyView(EmptyView().onAppear {
                // Record when someone sees the full announcement while in early access so we don't show it again to them when we move to full release.
                UserDefaults.standard.setValue(true, forKey: "WhatsNew.Bookmarks.EarlyAccess.Seen")
            }) },
            title: "Early Access Normal Title",
            message: "Message",
            buttonTitle: "Button",
            action: {},
            isEnabled: PaidFeature.bookmarks.inEarlyAccess && BuildEnvironment.current != .testFlight && SubscriptionHelper.activeTier == .patron
        ),

        // Bookmarks: Full Release
        // Show for everyone, except those who saw the `Early Access: Release` announcement
        .init(
            version: "99.99",
            header: { AnyView(EmptyView()) },
            title: "Release Title",
            message: "Message",
            buttonTitle: "Button",
            action: {},
            isEnabled: !PaidFeature.bookmarks.inEarlyAccess && !UserDefaults.standard.bool(forKey: "WhatsNew.Bookmarks.EarlyAccess.Seen")
        )
    ]
}

class AnnouncementFlow {
    static let shared = AnnouncementFlow()

    var isShowingAutoplayOption = false
}
