import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct Announcements {
    // Order is important.
    // In the case a user migrates to, let's say, 7.10 to 7.15 and
    // there were two announcements, the last one will be picked.
    var announcements: [WhatsNew.Announcement] = [
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
        )
    ]

    init() {
        addBookmarksEarlyAccessAnnouncement()
    }

    /// Add the bookmarks announcement when in Early Access.
    ///
    /// Since the beta and App Store binaries are the same we'll dynamically determine:
    /// - If we're in beta we'll show a "join beta testing" message for Plus and Patron
    /// - If we're in production we'll show the regular announcement for Patron
    ///
    /// If not we don't show the what's new at all.
    mutating func addBookmarksEarlyAccessAnnouncement() {
        guard FeatureFlag.bookmarks.enabled, PaidFeature.bookmarks.inEarlyAccess else { return }

        let activeTier = SubscriptionHelper.activeTier
        let environment = BuildEnvironment.current
        let isBeta = environment == .testFlight

        // Check to determine if we are showing the announcement
        let shouldShowInBeta = isBeta && activeTier > .none
        let shouldShowInRelease = !isBeta && activeTier == .patron

        // Don't add the announcement if we're not showing it
        guard shouldShowInBeta || shouldShowInRelease else { return }

        let title = isBeta ? "Beta Title" : "Normal Title"

        // TODO: Update with the real content
        let announcement = WhatsNew.Announcement(
            version: "99.99",
            header: {
                AnyView(AutoplayWhatsNewHeader().onAppear {
                    // Record when someone sees the full announcement while in early access so we don't show it again
                    // to them when we move to full release.
                    if shouldShowInRelease {
                        UserDefaults.standard.setValue(true, forKey: "WhatsNew.Bookmarks.EarlyAccess.Seen")
                    }
                })
            },
            title: title,
            message: "Bookmarks Message",
            buttonTitle: "Action Button",
            action: { }
        )

        announcements.append(announcement)
    }

    /// When bookmarks is out of early access we'll show the announcement to everyone
    /// but don't show it to people who already saw the full announcement when it was in early access
    /// This is a placeholder for now.
    /**
    mutating func addBookmarksReleaseAnnouncement() {
        guard
            FeatureFlag.bookmarks.enabled, !PaidFeature.bookmarks.inEarlyAccess,
            !UserDefaults.standard.bool(forKey: "WhatsNew.Bookmarks.EarlyAccess.Seen")
        else {
            return
        }

        // TODO: Update with the real content
        let announcement = WhatsNew.Announcement(
            version: "99.99",
            header: {
                AnyView(AutoplayWhatsNewHeader())
            },
            title: "Normal Title",
            message: "Bookmarks Message",
            buttonTitle: "Action Button",
            action: { }
        )

        announcements.append(announcement)
    }
     */
}

class AnnouncementFlow {
    static let shared = AnnouncementFlow()

    var isShowingAutoplayOption = false
}
