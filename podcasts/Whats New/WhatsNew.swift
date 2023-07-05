import Foundation

class WhatsNew {
    struct Announcement {
        let version: Double
        let image: String
        let title: String
        let message: String
    }

    let announcements: [Announcement]
    let currentVersion: Double
    let previousOpenedVersion: Double?

    init(announcements: [Announcement] = Announcements().announcements, previousOpenedVersion: Double? = UserDefaults.standard.string(forKey: Constants.UserDefaults.lastRunVersion)?.toDouble(), currentVersion: Double = Settings.appVersion().toDouble()) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion
        self.currentVersion = currentVersion
    }

    func viewControllerToShow() -> UIViewController? {
        guard let previousOpenedVersion,
              previousOpenedVersion != currentVersion,
              let announcement = announcements.last(where: { $0.version > previousOpenedVersion && $0.version <= currentVersion }) else {
            return nil
        }

        return UIViewController()
    }
}
