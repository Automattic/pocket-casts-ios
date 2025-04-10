import Foundation
import PocketCastsUtils

enum NotificationType: String {

    case onboardingSignUp
    case onboardingImport
    case onboardingThemes
    case onboardingUpNext
    case onboardingFilters
    case onboardingUpsell

    var title: String {
        switch self {
        case .onboardingSignUp:
            return L10n.notificationsOnboardingSignupTitle
        case .onboardingImport:
            return L10n.notificationsOnboardingImportTitle
        case .onboardingThemes:
            return L10n.notificationsOnboardingThemesTitle
        case .onboardingUpNext:
            return L10n.notificationsOnboardingUpnextTitle
        case .onboardingFilters:
            return L10n.notificationsOnboardingFiltersTitle
        case .onboardingUpsell:
            return L10n.notificationsOnboardingUpsellTitle
        }
    }

    var body: String {
        switch self {
        case .onboardingSignUp:
            return L10n.notificationsOnboardingSignupBody
        case .onboardingImport:
            return L10n.notificationsOnboardingImportBody
        case .onboardingThemes:
            return L10n.notificationsOnboardingThemesBody
        case .onboardingUpNext:
            return L10n.notificationsOnboardingUpnextBody
        case .onboardingFilters:
            return L10n.notificationsOnboardingFiltersBody
        case .onboardingUpsell:
            return L10n.notificationsOnboardingUpsellBody
        }
    }

    var identifier: String {
        return self.rawValue
    }

    var link: String {
        switch self {
        case .onboardingSignUp:
            return "pktc://signup"
        case .onboardingImport:
            return "pktc://settings/import"
        case .onboardingThemes:
            return "pktc://settings/themes"
        case .onboardingUpNext:
            return "pktc://upnext/?location=tab"
        case .onboardingFilters:
            return "pktc://filters"
        case .onboardingUpsell:
            return "pktc://upsell"
        }
    }
}

class NotificationsCoordinator {

    static let shared: NotificationsCoordinator = NotificationsCoordinator()

    var timeIntervalStep: TimeInterval = 24.hours

    private init() {

    }

    private let onboardingNotifications: [NotificationType] = [.onboardingSignUp, .onboardingImport, .onboardingUpNext, .onboardingFilters, .onboardingThemes, .onboardingUpsell]

    func setupOnboardingNotifications() {
        Settings.notificationsOnboardingTips = true
        NotificationsHelper.shared.registerForPushNotifications { granted in
            guard granted else { return }
            var timeInterval: TimeInterval = self.timeIntervalStep
            self.onboardingNotifications.forEach { notification in
                self.scheduleNotification(notification, timeInterval: timeInterval)
                timeInterval += self.timeIntervalStep
            }
        }
    }

    func cancelOnboardingNotifications() {
        Settings.notificationsOnboardingTips = false
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
                FileLog.shared.addMessage("[Notifications Coordinator] Error adding notification: \(error)")
            }
        }
    }
}
