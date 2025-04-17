import Foundation
import PocketCastsUtils

enum NotificationType: String {

    case onboardingSignUp
    case onboardingImport
    case onboardingThemes
    case onboardingStaffPicks
    case onboardingUpNext
    case onboardingFilters
    case onboardingUpsell

    case reengagementWeekly

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
        case .onboardingStaffPicks:
            return L10n.notificationsOnboardingStaffPicksTitle
        case .reengagementWeekly:
            return "We miss you!"
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
        case .onboardingStaffPicks:
            return L10n.notificationsOnboardingStaffPicksBody
        case .reengagementWeekly:
            return "It’s been awhile since you’ve listened. Jump back in and enjoy!"
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
        case .onboardingStaffPicks:
            return "pktc://discover/staff-picks"
        case .reengagementWeekly:
            return "pktc://open"
        }
    }
}

class NotificationsCoordinator {

    static let shared: NotificationsCoordinator = NotificationsCoordinator()

    var onboardingTimeIntervalStep: TimeInterval = 24.hours
    var reEngagementTimeIntervalStep: TimeInterval = 1.week
    var ignoreScheduleHours: Bool = false

    enum Constants {
        static let onboardingScheduleHour: Int = 10
        static let reengagementScheduleHour: Int = 16
    }

    private let notificationCenter: UNUserNotificationCenter

    private init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    let onboardingNotifications: [NotificationType] = [.onboardingSignUp, .onboardingImport, .onboardingUpNext, .onboardingFilters, .onboardingThemes, .onboardingStaffPicks, .onboardingUpsell]

    func setupDailyRemindersNotifications() {
        Settings.notificationsDailyReminders = true
        NotificationsHelper.shared.registerForPushNotifications { [weak self] granted in
            guard let self, granted else { return }
            let timeIntervalToSchedule: TimeInterval = calculateTimeIntervalToHour(Constants.onboardingScheduleHour)
            var timeInterval: TimeInterval = timeIntervalToSchedule + onboardingTimeIntervalStep
            onboardingNotifications.forEach { notification in
                self.scheduleNotification(notification, timeInterval: timeInterval)
                timeInterval += self.onboardingTimeIntervalStep
            }
        }
    }

    func cancelDailyRemainderNotifications() {
        Settings.notificationsDailyReminders = false
        notificationCenter.removePendingNotificationRequests(withIdentifiers: onboardingNotifications.map { $0.identifier })
    }

    func setupNewFeaturesAndTipsNotifications() {
        Settings.notificationsNewFeaturesAndTips = true
        NotificationsHelper.shared.registerForPushNotifications { [weak self] granted in
            guard granted else { return }
            self?.updateReengamentNotifications()
        }
    }

    func cancelNewFeaturesAndTipsNotifications() {
        Settings.notificationsNewFeaturesAndTips = false
        cancelNotification(.reengagementWeekly)
    }

    func updateReengamentNotifications() {
        cancelNotification(.reengagementWeekly)
        let timeIntervalToSchedule: TimeInterval = calculateTimeIntervalToHour(Constants.reengagementScheduleHour)
        let initialInterval = timeIntervalToSchedule + reEngagementTimeIntervalStep
        scheduleNotification(.reengagementWeekly, timeInterval: initialInterval, repeats: false)
        scheduleNotification(.reengagementWeekly, timeInterval: initialInterval + reEngagementTimeIntervalStep, repeats: true)
    }

    func scheduleNotification(_ type: NotificationType, timeInterval: TimeInterval = 5.seconds, repeats: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.categoryIdentifier = NotificationsHelper.NotificationsCategory.deepLink.rawValue
        content.userInfo = ["destination_url": type.link]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)

        let request = UNNotificationRequest(identifier: type.identifier, content: content, trigger: trigger)

        // Schedule the request with the system.
        Task {
            do {
                try await notificationCenter.add(request)
            } catch {
                // Handle errors that may occur during add.
                FileLog.shared.addMessage("[Notifications Coordinator] Error adding notification: \(error)")
            }
        }
    }

    func cancelNotification(_ type: NotificationType) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [type.identifier])
    }

    private func calculateTimeIntervalToHour(_ hour: Int) -> TimeInterval {
        if ignoreScheduleHours {
            return 1
        }
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date.now, matchingPolicy: .nextTime) else {
            return 0
        }
        return date.timeIntervalSince(Date.now)
    }
}
