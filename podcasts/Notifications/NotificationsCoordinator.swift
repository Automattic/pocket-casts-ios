import Foundation

enum NotificationType: String {

    case onboardingThemes

    var title: String {
        switch self {
        case .onboardingThemes:
            return "Time for a new look"
        }
    }

    var body: String {
        switch self {
        case .onboardingThemes:
            return "Browse our themes and find the one that suits your style."
        }
    }

    var identifier: String {
        switch self {
        case .onboardingThemes:
            return self.rawValue
        }
    }

    var link: String {
        switch self {
        case .onboardingThemes:
            return "pktc://settings/themes"
        }
    }
}

class NotificationsCoordinator {

    static var shared: NotificationsCoordinator = NotificationsCoordinator()

    private init() {

    }

    func setupOnboardingNotifications() {
        scheduleNotification(.onboardingThemes)
    }

    func scheduleNotification(_ type: NotificationType, timeInterval: TimeInterval = 5.seconds) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.categoryIdentifier = NotificationsHelper.NotificationsCategory.deepLink.rawValue
        content.userInfo = ["destination_url": type.link]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(identifier: type.identifier, content: content, trigger: trigger)

        // Schedule the request with the system.
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            do {
                try await notificationCenter.add(request)
            } catch {
                // Handle errors that may occur during add.
            }
        }
    }
}
