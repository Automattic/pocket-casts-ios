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

        return UIViewController()
    }
}
