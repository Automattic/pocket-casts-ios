import Foundation

enum NotificationType: String {

    case onboardingSignIn
    case onboardingImport
    case onboardingThemes
    case onboardingUpNext
    case onboardingFilters

    var title: String {
        switch self {
        case .onboardingSignIn:
            return "Your shows, on any device!"
        case .onboardingImport:
            return "Easily import your podcasts"
        case .onboardingThemes:
            return "Time for a new look"
        case .onboardingUpNext:
            return "Simplify your queue"
        case .onboardingFilters:
            return "Organize your episodes"
        }
    }

    var body: String {
        switch self {
        case .onboardingSignIn:
            return "Create a free account to sync your shows and listen anywhere."
        case .onboardingImport:
            return "Switching from another app? Bring all your favorite shows to Pocket Casts."
        case .onboardingThemes:
            return "Browse our themes and find the one that suits your style."
        case .onboardingUpNext:
            return "Build a playback queue and say goodbye to jumping around between episodes."
        case .onboardingFilters:
            return "Create smart filters to organize your episodes."
        }
    }

    var identifier: String {
        return self.rawValue
    }

    var link: String {
        switch self {
        case .onboardingSignIn:
            return "pktc://signup"
        case .onboardingImport:
            return "pktc://settings/import"
        case .onboardingThemes:
            return "pktc://settings/themes"
        case .onboardingUpNext:
            return "pktc://upnext/?location=tab"
        case .onboardingFilters:
            return "pktc://filters"
        }
    }
}

class NotificationsCoordinator {

    static var shared: NotificationsCoordinator = NotificationsCoordinator()

    private init() {

    }

    private let onboardingNotifications: [NotificationType] = [.onboardingSignIn, .onboardingImport, .onboardingUpNext, .onboardingFilters, .onboardingThemes]

    func setupOnboardingNotifications() {
        let timeIntervalStep: TimeInterval = 5.seconds
        var timeInterval: TimeInterval = timeIntervalStep
        onboardingNotifications.forEach { notification in
            scheduleNotification(notification, timeInterval: timeInterval)
            timeInterval += timeIntervalStep
        }
    }

    func cancelOnboardingNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: onboardingNotifications.map { $0.identifier })
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
