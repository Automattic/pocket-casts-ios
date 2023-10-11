import Foundation
import SwiftUI

class WhatsNew {
    struct Announcement {
        let version: String
        let header: () -> AnyView
        let title: String
        let message: String
        let buttonTitle: String
        let action: () -> Void
        var isEnabled: Bool = true
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
        guard let previousOpenedVersion,
              previousOpenedVersion != currentVersion,
              let announcement = announcements.last(where: { $0.version > previousOpenedVersion && $0.version <= currentVersion }),
              announcement.version != lastWhatsNewShown else {
            return nil
        }

        let whatsNewViewController = ThemedHostingController(rootView: WhatsNewView(announcement: announcement))
        whatsNewViewController.modalPresentationStyle = .overCurrentContext
        whatsNewViewController.modalTransitionStyle = .crossDissolve
        whatsNewViewController.view.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.5)

        return whatsNewViewController
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
