import Foundation
import SwiftUI
import WhatsNew

class WhatsNewPresenter {
    let announcements: [WhatsNew.Announcement]
    let currentVersion: String
    let previousOpenedVersion: String?
    let lastWhatsNewShown: String?

    init(announcements: [WhatsNew.Announcement] = Announcements().announcements, previousOpenedVersion: String? = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastRunVersion), currentVersion: String = Settings.appVersion(), lastWhatsNewShown: String? = Settings.lastWhatsNewShown) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion.map(WhatsNew.normalizedVersion)
        self.currentVersion = WhatsNew.normalizedVersion(currentVersion)
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

    /// Returns the announcement to be displayed if one is available.
    var visibleAnnouncement: WhatsNew.Announcement? {
        // On first run, stamp `lastWhatsNewShown` so announcements don't
        // appear for the version the user is installing fresh.
        if previousOpenedVersion == nil {
            Settings.lastWhatsNewShown = currentVersion
        }

        return WhatsNew.visibleAnnouncement(
            from: announcements,
            previousOpenedVersion: previousOpenedVersion,
            currentVersion: currentVersion,
            lastWhatsNewShown: lastWhatsNewShown
        )
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

extension WhatsNewPresenter {
    static var slumberAnnouncement: WhatsNew.Announcement? {
        WhatsNewPresenter().announcements.first(where: { $0.version == "7.57" })
    }
}
