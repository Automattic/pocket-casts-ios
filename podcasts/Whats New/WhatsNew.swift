import Foundation

struct WhatsNewAnnouncement {
    let version: Double
    let image: String
    let title: String
    let message: String
}

class WhatsNew {
    let announcements: [WhatsNewAnnouncement]
    let currentVersion: Double
    let previousOpenedVersion: Double

    init(announcements: [WhatsNewAnnouncement], previousOpenedVersion: Double, currentVersion: Double) {
        self.announcements = announcements
        self.previousOpenedVersion = previousOpenedVersion
        self.currentVersion = currentVersion
    }

    func showIfNeeded() -> Bool {
        guard let announcement = announcements.filter { $0.version >= previousOpenedVersion }.last else {
            return false
        }

        return true
    }
}
