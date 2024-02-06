import Foundation
import PocketCastsServer
import SwiftUI

class WhatsNew {
    struct Announcement {
        let version: String
        let header: () -> AnyView
        let title: String
        let message: String
        let buttonTitle: String
        let action: () -> Void
        let displayTier: SubscriptionTier
        let isEnabled: () -> Bool
        let fullModal: Bool

        init(version: String,
             header: @autoclosure @escaping () -> AnyView,
             title: String, message: String,
             buttonTitle: String,
             action: @escaping () -> Void,
             displayTier: SubscriptionTier = .none,
             isEnabled: @autoclosure @escaping () -> Bool,
             fullModal: Bool = false) {
            self.version = version
            self.header = header
            self.title = title
            self.message = message
            self.buttonTitle = buttonTitle
            self.action = action
            self.displayTier = displayTier
            self.isEnabled = isEnabled
            self.fullModal = fullModal
        }
    }

    let announcements: [Announcement]
    let currentVersion: String
    let previousOpenedVersion: String?
    let lastWhatsNewShown: String?

    init(announcements: [Announcement] = Announcements().announcements, previousOpenedVersion: String? = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastRunVersion), currentVersion: String = Settings.appVersion(), lastWhatsNewShown: String? = Settings.lastWhatsNewShown) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion?.majorMinor
        self.currentVersion = currentVersion.majorMinor
        self.lastWhatsNewShown = lastWhatsNewShown
    }

    func viewControllerToShow() -> UIViewController? {
        guard let announcement = visibleAnnouncement else {
            return nil
        }

        guard !announcement.fullModal else {
            let whatsNewViewController = ThemedHostingController(rootView: WhatsNewFullView(announcement: announcement)
                .onAppear {
                    Settings.lastWhatsNewShown = announcement.version
                })

            return whatsNewViewController.usingSheetPresentationController()
        }

        let whatsNewViewController = ThemedHostingController(rootView: WhatsNewView(announcement: announcement))
        whatsNewViewController.modalPresentationStyle = .overCurrentContext
        whatsNewViewController.modalTransitionStyle = .crossDissolve
        whatsNewViewController.view.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.5)

        return whatsNewViewController
    }

    /// Returns the announcement to be displayed if one is available
    var visibleAnnouncement: Announcement? {
        // Don't show any announcements if this is the first run of the app,
        // or if we've already checked the what's new for this version
        guard let previousOpenedVersion, previousOpenedVersion != currentVersion else {
            return nil
        }

        // Find the last announcement that:
        // - is enabled
        // - has not been shown already
        // - the target version is not before the last opened version, and not for a future version
        return announcements
            .last(where: {
                $0.isEnabled() &&
                $0.version != lastWhatsNewShown &&
                $0.version.inRange(of: previousOpenedVersion, upper: currentVersion)
            })
    }
}

extension UIViewController {
    func usingSheetPresentationController() -> Self {
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.prefersGrabberVisible = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }

        return self
    }
}

extension WhatsNew {
    static var slumberAnnouncement: Announcement? {
        WhatsNew().announcements.first(where: { $0.version == "7.57" })
    }
}

private extension String {
    /// Given a semver string, ie.: "7.42", "7.43.0.1", "7.43.1"
    /// returns it in the format of MAJOR.MINOR
    /// Eg.: "7.43", "7.43.0.1" or "7.43.1" will return "7.43"
    var majorMinor: String {
        let splitVersion = split(separator: ".")

        guard let major = splitVersion[safe: 0],
              let minor = splitVersion[safe: 1] else {
            return self
        }

        return "\(major).\(minor)"
    }

    /// Returns whether the version is above the `lower` and equal to or below the `upper` bounds
    func inRange(of lower: String, upper: String) -> Bool {
        self > lower && self <= upper
    }
}
