import Foundation

class NotificationsCoordinator {

    static var shared: NotificationsCoordinator = NotificationsCoordinator()

    private init() {

    }

    func setupOnboardingNotifications() {
        makeOnboardingThemeNotification()
    }

    func makeOnboardingThemeNotification(timeInterval: TimeInterval = 5.seconds) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a new look"
        content.body = "Browse our themes and find the one that suits your style."
        content.categoryIdentifier = NotificationsHelper.NotificationsCategory.deepLink.rawValue
        content.userInfo = ["destination_url": "pktc://settings/themes"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

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
