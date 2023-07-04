import Foundation
import SwiftUI

struct WhatsNewAnnouncement {
    let version: Double
    let image: String
    let title: String
    let message: String
}

class WhatsNew {
    let announcements: [WhatsNewAnnouncement]
    let currentVersion: Double
    let previousOpenedVersion: Double?

    init(announcements: [WhatsNewAnnouncement] = Announcements().announcements, previousOpenedVersion: Double? = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastRunVersion)?.toDouble(), currentVersion: Double = Settings.appVersion().toDouble()) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion
        self.currentVersion = currentVersion
    }

    func viewControllerToShow() -> UIViewController? {
        guard let previousOpenedVersion,
              let announcement = announcements.filter({ $0.version >= previousOpenedVersion && $0.version <= currentVersion }).last else {
            return nil
        }

        let whatsNewViewController = ThemedHostingController(rootView: WhatsNewView(announcement: announcement))
        whatsNewViewController.modalPresentationStyle = .overCurrentContext
        whatsNewViewController.modalTransitionStyle = .crossDissolve
        whatsNewViewController.view.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.5)

        return whatsNewViewController
    }
}
