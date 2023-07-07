import Foundation
import SwiftUI

class WhatsNew {
    struct Announcement {
        let version: Double
        let header: () -> AnyView
        let title: String
        let message: String
        let buttonTitle: String
        let action: () -> Void
    }

    let announcements: [Announcement]
    let currentVersion: Double
    let previousOpenedVersion: Double?

    init(announcements: [Announcement] = Announcements().announcements, previousOpenedVersion: String? = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastRunVersion), currentVersion: String = Settings.appVersion()) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion?.toDouble()
        self.currentVersion = currentVersion.toDouble()
    }

    func viewControllerToShow() -> UIViewController? {
        guard let previousOpenedVersion,
              previousOpenedVersion != currentVersion,
              let announcement = announcements.last(where: { $0.version > previousOpenedVersion && $0.version <= currentVersion }) else {
            return nil
        }

        let whatsNewViewController = ThemedHostingController(rootView: WhatsNewView(announcement: announcement))
        whatsNewViewController.modalPresentationStyle = .overCurrentContext
        whatsNewViewController.modalTransitionStyle = .crossDissolve
        whatsNewViewController.view.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.5)

        return whatsNewViewController
    }
}
