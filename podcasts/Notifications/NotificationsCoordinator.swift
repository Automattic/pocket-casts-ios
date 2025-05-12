import Foundation
import PocketCastsUtils
import PocketCastsServer
import PocketCastsDataModel

enum NotificationType: String {

    case onboardingSignUp
    case onboardingImport
    case onboardingThemes
    case onboardingStaffPicks
    case onboardingUpNext
    case onboardingFilters
    case onboardingUpsell

    case reengagementWeekly
    case reengagementDownloads

    case recommendationsTrending
    case recommendationsYouMightLike

    case upsell
    case newFeatureSuggestedFolders

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
            return L10n.notificationsReengagementWeeklyTitle
        case .reengagementDownloads:
                return L10n.notificationsReengagementDownloadsTitle
        case .recommendationsTrending:
            return L10n.notificationsRecommendationsTrendingTitle
        case .recommendationsYouMightLike:
            return L10n.notificationsRecommendationsYouMightLikeTitle
        case .upsell:
            return L10n.notificationsOffersUpsellTitle
        case .newFeatureSuggestedFolders:
            return L10n.notificationsNewFeatureSuggestedFoldersTitle
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
            return L10n.notificationsReengagementWeeklyBody
        case .reengagementDownloads:
                return L10n.notificationsReengagementDownloadsBody(NotificationsCoordinator.shared.numberOfDownloadsAvailable())
        case .recommendationsTrending:
            return L10n.notificationsRecommendationsTrendingBody
        case .recommendationsYouMightLike:
            return L10n.notificationsRecommendationsYouMightLikeBody
        case .upsell:
            return L10n.notificationsOffersUpsellBody
        case .newFeatureSuggestedFolders:
            return L10n.notificationsNewFeatureSuggestedFoldersBody
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
            return "pktc://discover"
        case .reengagementDownloads:
            return "pktc://profile/downloads"
        case .recommendationsTrending:
            return "pktc://discover/trending"
        case .recommendationsYouMightLike:
            return "pktc://discover/recommendations_user"
        case .upsell:
            return "pktc://upsell"
        case .newFeatureSuggestedFolders:
            return "pktc://features/suggestedFolders"
        }
    }

    var shouldSend: Bool {
        if !self.isRepeatable, Settings.notificationsLastTriggerDate[self.rawValue] != nil {
            return false
        }
        switch self {
            case .onboardingSignUp:
                return !SyncManager.isUserLoggedIn()
            case .onboardingUpsell, .upsell:
                return !SubscriptionHelper.hasActiveSubscription()
            case .recommendationsYouMightLike:
                return SyncManager.isUserLoggedIn()
            case .newFeatureSuggestedFolders:
                return Settings.suggestedFoldersUpsellCount < 2 && Settings.appVersion() == "7.88"
            case .reengagementDownloads:
                return NotificationsCoordinator.shared.numberOfDownloadsAvailable() > 0
            default:
                return true
        }
    }

    var isRepeatable: Bool {
        switch self {
            case .reengagementWeekly,
                 .reengagementDownloads,
                 .recommendationsTrending,
                 .recommendationsYouMightLike,
                 .upsell:
                return true
            default:
                return false
        }
    }

}

enum NotificationsGroup: CaseIterable {

    case newEpisodes
    case dailyReminders
    case recommendations
    case newFeaturesAndTips
    case offers

    var notifications: [NotificationType] {
        switch self {
            case .newEpisodes:
                return [] // New Episodes are notifications sent by the server, so they don't need a local implementation
            case .dailyReminders:
                return [.onboardingSignUp, .onboardingImport, .onboardingUpNext, .onboardingFilters, .onboardingThemes, .onboardingStaffPicks, .onboardingUpsell]
            case .recommendations:
                return [.recommendationsTrending, .recommendationsYouMightLike]
            case .newFeaturesAndTips:
                return [.newFeatureSuggestedFolders, .reengagementWeekly, .reengagementDownloads]
            case .offers:
                return [.upsell]
        }
    }

    var scheduleHour: Int {
        switch self {
            case .newEpisodes:
                return 0 // This is determined by the server
            case .dailyReminders:
                return 10
            case .recommendations:
                return 11
            case .newFeaturesAndTips:
                return 16
            case .offers:
                return 14
        }
    }

    var isEnabled: Bool {
        switch self {
            case .newEpisodes:
                return Settings.notificationsNewEpisodes
            case .dailyReminders:
                return Settings.notificationsDailyReminders
            case .recommendations:
                return Settings.notificationsRecommendations
            case .newFeaturesAndTips:
                return Settings.notificationsNewFeaturesAndTips
            case .offers:
                return Settings.notificationsOffers
        }
    }

    func setEnabled(_ newValue: Bool) {
        switch self {
            case .newEpisodes:
                if newValue {
                    // the user has just turned on push, enable it for all their podcasts for simplicity
                    DataManager.sharedManager.setPushForAllPodcasts(pushEnabled: true)
                    NotificationsHelper.shared.registerForPushNotifications()
                } else {
                    RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
                }
                Settings.notificationsNewEpisodes = newValue
            case .dailyReminders:
                Settings.notificationsDailyReminders = newValue
            case .recommendations:
                Settings.notificationsRecommendations = newValue
            case .newFeaturesAndTips:
                Settings.notificationsNewFeaturesAndTips = newValue
            case .offers:
                Settings.notificationsOffers = newValue
        }
    }

    // Variable to be used only in debugging/testing to accelarate notifications schedule
    static var speedUpNotifications: Bool = false

    var timeIntervalStep: TimeInterval {
        switch self {
            case .newEpisodes:
                return 0
            case .dailyReminders:
                return Self.speedUpNotifications ? 10.seconds: 24.hours
            case .recommendations:
                return Self.speedUpNotifications ? 60.seconds: 3.days
            case .newFeaturesAndTips:
                return Self.speedUpNotifications ? 60.seconds: 1.week
            case .offers:
                return Self.speedUpNotifications ? 120.seconds: 2.week
        }
    }

    static var allDisabled: Bool {
        Self.allCases.allSatisfy() {
            $0.isEnabled == false
        }
    }
}

class NotificationsCoordinator {

    static let shared: NotificationsCoordinator = NotificationsCoordinator()

    var ignoreScheduleHours: Bool = false

    private let notificationCenter: UNUserNotificationCenter

    private init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    @discardableResult
    func requestAndSetupInitialPermissions() async -> Bool {
        await withCheckedContinuation { continuation in
            NotificationsHelper.shared.registerForPushNotifications() { granted in
                guard granted else {
                    continuation.resume(returning: false)
                    return
                }
                // activate all notifications
                for group in NotificationsGroup.allCases {
                    self.setupNotifications(for: group)
                }
                continuation.resume(returning: granted)
            }
        }
    }

    func setupNotifications(for group: NotificationsGroup) {
        group.setEnabled(true)
        NotificationsHelper.shared.enablePush()
        NotificationsHelper.shared.registerForPushNotifications { [weak self] granted in
            guard let self, granted else { return }
            updateNotifications(for: group)
        }
    }

    func updateNotifications(for group: NotificationsGroup) {
        cancelNotifications(for: group)
        let timeIntervalToSchedule: TimeInterval = calculateTimeIntervalToHour(group.scheduleHour)
        var timeInterval: TimeInterval = timeIntervalToSchedule + group.timeIntervalStep
        for notification in group.notifications {
            guard notification.shouldSend else {
                continue
            }
            if notification.isRepeatable {
                scheduleNotification(notification, timeInterval: timeInterval, repeats: false)
                scheduleNotification(notification, timeInterval: timeInterval + group.timeIntervalStep, repeats: true)
            } else {
                scheduleNotification(notification, timeInterval: timeInterval, repeats: false)
            }
            timeInterval += group.timeIntervalStep
        }
    }

    func disableNotifications(for group: NotificationsGroup) {
        group.setEnabled(false)
        cancelNotifications(for: group)
        if NotificationsGroup.allDisabled {
            NotificationsHelper.shared.disablePush()
        }
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

    func markNotification(_ notification: NotificationType) {
        var notificationDates = Settings.notificationsLastTriggerDate
        notificationDates[notification.rawValue] = Date.now
        Settings.notificationsLastTriggerDate = notificationDates
    }

    func cancelNotifications(for group: NotificationsGroup) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: group.notifications.map { $0.identifier })
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

    private lazy var episodesDataManager: EpisodesDataManager = {
        return EpisodesDataManager()
    }()

    func numberOfDownloadsAvailable() -> Int {
        episodesDataManager.downloadedEpisodes().reduce(0) { partialResult, list in
            return partialResult + list.elements.count
        }
    }
}
