import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsUtils
import StoreKit

@MainActor
public class UserSatisfactionSurveyManager: NSObject {
    public static let shared = UserSatisfactionSurveyManager()

    private var currentEvent: SurveyTriggerEvent?

    var episodeCompletionCount: Int {
        get { UserDefaults.standard.integer(forKey: "surveyEpisodeCompletionCount") }
        set { UserDefaults.standard.set(newValue, forKey: "surveyEpisodeCompletionCount") }
    }

    private var plusUpgradeDate: Date? {
        get { UserDefaults.standard.object(forKey: "surveyPlusUpgradeDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "surveyPlusUpgradeDate") }
    }

    private var deferredSurveyEvents: [SurveyTriggerEvent: [Date]] = [:]

    /// A survey that is ready to be shown, and is waiting for a moment when it won't interrupt
    private var pendingSurvey: PendingSurvey?
    private var pendingSurveyTask: Task<Void, Never>?

    /// When the app was last opened. `nil` until the first `applicationOpened` event arrives.
    private var appOpenedDate: Date?

    // MARK: - Survey Entry Points

    /// Checks if the survey should be shown based on the event and user context
    func shouldShowSurvey(for event: SurveyTriggerEvent) -> Bool {
        let result = checkSurveyEligibility(for: event)
        FileLog.shared.addMessage("UserSatisfactionSurveyManager: Should show survey for \(event.rawValue): \(result.displayReason)")
        return result.canShow
    }

    /// Checks survey eligibility and returns the specific reason
    func checkSurveyEligibility(for event: SurveyTriggerEvent) -> SurveyCheckResult {
        // Check if user has already left a review
        if hasUserLeftReview() {
            return .userLeftReview
        }

        // Check frequency limits (once per 30 days)
        if hasShownSurveyRecently() {
            return .shownRecently
        }

        // Check if user clicked "Not Really" within past 60 days
        if hasUserDeclinedRecently() {
            return .userDeclinedRecently
        }

        // Check user subscription status for appropriate entry points
        let isPlus = SubscriptionHelper.hasActiveSubscription()

        switch event {
        case .thirdEpisodeCompleted, .episodeStarred, .showRated, .filterCreated:
            return !isPlus ? .canShow : .wrongUserType // Free user events
        case .plusUpgraded, .folderCreated, .bookmarkCreated, .customThemeSet, .referralShared:
            return isPlus ? .canShow : .wrongUserType // Plus user events
        case .endOfYearStoryShared, .endOfYearCompleted:
            return .deferredEvent
        }
    }

    /// Presents the survey view
    func presentSurvey(from viewController: UIViewController, event: SurveyTriggerEvent, skipEligibility: Bool = false) {
        guard skipEligibility || shouldShowSurvey(for: event) else { return }

        guard let source = SceneHelper.rootViewController() else {
            assertionFailure("WARNING: Root View Controller not found so survey was not presented")
            FileLog.shared.addMessage("UserSatisfactionSurveyManager: Root View Controller not found so survey was not presented")
            return
        }

        let surveyView = UserSatisfactionSurveyView { [weak self] response in
            switch response {
            case .yes:
                Analytics.track(.userSatisfactionSurveyYesResponse, properties: [
                    "trigger_event": event.rawValue,
                    "user_type": SubscriptionHelper.hasActiveSubscription() ? "plus" : "free"
                ])
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        AppStore.requestReview(in: windowScene)
                        Settings.addReviewRequested()
                        Analytics.track(.appStoreReviewRequested, properties: ["source": AnalyticsSource.userSatisfactionSurvey])
                    }
                }
                self?.currentEvent = nil
            case .no:
                Analytics.track(.userSatisfactionSurveyNoResponse, properties: [
                    "trigger_event": event.rawValue,
                    "user_type": SubscriptionHelper.hasActiveSubscription() ? "plus" : "free"
                ])
                Settings.setSurveyNotReallyResponse()
                EmailHelper().presentSupportDialog(source, type: .satisfactionSurvey)
                self?.currentEvent = nil
            }
        }

        let hostingController = ThemedHostingController(rootView: surveyView, background: \.primaryUi01)

        // Let the hosting controller size itself
        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.presentationController?.delegate = self

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [
                .custom { context in
                    let size = hostingController.sizeThatFits(in: CGSize(width: context.maximumDetentValue, height: .greatestFiniteMagnitude))
                    return size.height
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        source.present(hostingController, animated: true)
        currentEvent = event
        Settings.addSurveyPresented()
        Analytics.track(.userSatisfactionSurveyShown, properties: [
            "trigger_event": event.rawValue,
            "user_type": SubscriptionHelper.hasActiveSubscription() ? "plus" : "free"
        ])
    }

    // MARK: - Helper Methods

    private func hasUserLeftReview() -> Bool {
        return !Settings.reviewRequestDates().isEmpty
    }

    private func hasShownSurveyRecently() -> Bool {
        let surveyDates = Settings.surveyPresentationDates()
        guard let lastSurveyDate = surveyDates.last else { return false }

        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return lastSurveyDate > thirtyDaysAgo
    }

    private func hasUserDeclinedRecently() -> Bool {
        guard let lastDeclineDate = Settings.lastSurveyNotReallyDate() else { return false }

        let sixtyDaysAgo = Date().addingTimeInterval(-60 * 24 * 60 * 60)
        return lastDeclineDate > sixtyDaysAgo
    }
}

extension UserSatisfactionSurveyManager: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Analytics.track(.userSatisfactionSurveyDismissed, properties: [
            "trigger_event": currentEvent?.rawValue ?? "unknown",
            "user_type": SubscriptionHelper.hasActiveSubscription() ? "plus" : "free"
        ])
        currentEvent = nil
    }
}

// MARK: - AnalyticsAdapter

extension UserSatisfactionSurveyManager: AnalyticsAdapter {
    public func track(name: String, properties: [String: Sendable]) async {
        if name == AnalyticsEvent.applicationOpened.eventName {
            appOpenedDate = Date()
            // Pick up a survey that was triggered while the app was in the background
            showPendingSurveyWhenCalm()
        }

        let handled = handleDeferredSurveyReleaseIfNeeded(for: name, properties: properties)

        guard handled == false else {
            // We already triggered a deferred event so skip this
            return
        }

        guard let analyticsEvent = mapAnalyticsEventToSurveyTrigger(name: name, properties: properties) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.presentSurveyIfEligible(for: analyticsEvent)
        }
    }

    private func mapAnalyticsEventToSurveyTrigger(name: String, properties: [String: Sendable]) -> SurveyTriggerEvent? {
        switch name {
        case AnalyticsEvent.episodeStarred.eventName:
            return .episodeStarred
        case AnalyticsEvent.ratingScreenSubmitTapped.eventName:
            return .showRated
        case AnalyticsEvent.filterCreated.eventName:
            return .filterCreated
        case AnalyticsEvent.folderSaved.eventName:
            return .folderCreated
        case AnalyticsEvent.bookmarkEditFormSubmitted.eventName:
            return .bookmarkCreated
        case AnalyticsEvent.referralPassShared.eventName:
            return .referralShared
        case AnalyticsEvent.settingsAppearanceThemeChanged.eventName:
            return .customThemeSet
        case AnalyticsEvent.episodeMarkedAsPlayed.eventName:
            return handleEpisodeCompletion()
        case AnalyticsEvent.purchaseSuccessful.eventName:
            return handlePlusUpgrade()
        case AnalyticsEvent.applicationOpened.eventName:
            return handleAppOpened()
        case AnalyticsEvent.endOfYearStoryShared.eventName:
            return .endOfYearStoryShared
        case AnalyticsEvent.endOfYearStoryShown.eventName:
            if properties["story"] as? String == "ending" {
                return .endOfYearCompleted
            }
            return nil
        default:
            return nil
        }
    }

    private func presentSurveyIfEligible(for event: SurveyTriggerEvent, allowDeferral: Bool = true) {
        let result = allowDeferral ? checkSurveyEligibility(for: event) : .canShow

        switch result {
        case .canShow:
            FileLog.shared.addMessage("UserSatisfactionSurveyManager: Survey for \(event.rawValue) will be shown at the next calm moment")
            pendingSurvey = PendingSurvey(event: event, skipEligibility: !allowDeferral)
            showPendingSurveyWhenCalm()
        case .deferredEvent:
            deferSurveyTrigger(event)
        default:
            break
        }
    }

    /// Shows the pending survey once it won't interrupt, and checks again later if it would.
    ///
    /// It follows the Android app's rules: the app has been open for a few seconds, nothing is presented over
    /// the main screens, and the screen hasn't just been touched. Unlike Android, it doesn't require being on
    /// the first screen of a tab.
    private func showPendingSurveyWhenCalm() {
        pendingSurveyTask?.cancel()
        pendingSurveyTask = nil

        guard let pendingSurvey else { return }

        // Nothing can be shown in the background. This is called again when the app is opened.
        guard UIApplication.shared.applicationState != .background else { return }

        let timeUntilAppHasSettled = remainingDelayAfterAppOpened()
        guard timeUntilAppHasSettled <= 0 else {
            checkPendingSurvey(after: timeUntilAppHasSettled)
            return
        }

        guard canShowSurveyWithoutInterrupting(), let topViewController = SceneHelper.rootViewController() else {
            checkPendingSurvey(after: PresentationTiming.retryInterval)
            return
        }

        self.pendingSurvey = nil
        presentSurvey(from: topViewController, event: pendingSurvey.event, skipEligibility: pendingSurvey.skipEligibility)
    }

    private func checkPendingSurvey(after delay: TimeInterval) {
        pendingSurveyTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.showPendingSurveyWhenCalm()
        }
    }

    /// How much longer to wait before the app has been open long enough to show the survey
    private func remainingDelayAfterAppOpened() -> TimeInterval {
        guard let appOpenedDate else { return 0 }
        return PresentationTiming.delayAfterAppOpened - Date().timeIntervalSince(appOpenedDate)
    }

    private func canShowSurveyWithoutInterrupting() -> Bool {
        guard UIApplication.shared.applicationState == .active,
              let mainController = SceneHelper.rootViewController(includeTopMost: false),
              let window = mainController.view.window else {
            return false
        }

        // The full screen player, Up Next, episode cards, sheets and alerts are all presented from the main controller
        if mainController.presentedViewController != nil {
            return false
        }

        if let window = window as? MainWindow, window.wasTouched(inLast: PresentationTiming.quietPeriodAfterTouch) {
            return false
        }

        return true
    }

    private func deferSurveyTrigger(_ event: SurveyTriggerEvent, ) {
        var dates: [Date] = deferredSurveyEvents[event] ?? []
        dates.append(Date())
        deferredSurveyEvents[event] = dates
    }

    private func handleDeferredSurveyReleaseIfNeeded(for analyticsEventName: String, properties: [String: Sendable]) -> Bool {
        let readyEvents = deferredSurveyEvents
            .filter { $0.key.shouldShowAnalytics(for: analyticsEventName, properties: properties) }

        readyEvents.forEach { deferredSurveyEvents.removeValue(forKey: $0.key) }

        guard let event = readyEvents.first else { return false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.presentSurveyIfEligible(for: event.key, allowDeferral: false)
        }

        return true
    }

    private func handleEpisodeCompletion() -> SurveyTriggerEvent? {
        episodeCompletionCount += 1

        if episodeCompletionCount == 3 {
            return .thirdEpisodeCompleted
        }

        return nil
    }

    private func handlePlusUpgrade() -> SurveyTriggerEvent? {
        let date = Date()
        FileLog.shared.addMessage("UserSatisfactionSurveyManager: Saved plus upgrade date at \(date)")
        plusUpgradeDate = date

        return nil
    }

    private func handleAppOpened() -> SurveyTriggerEvent? {
        // Check plus upgrade survey eligibility when app opens
        guard let upgradeDate = plusUpgradeDate else {
            // Track upgrade date if user has active subscription but no stored date
            if SubscriptionHelper.hasActiveSubscription() {
                let date = Date()
                FileLog.shared.addMessage("UserSatisfactionSurveyManager: Saved plus upgrade date at \(date)")
                plusUpgradeDate = date
            }
            return nil
        }

        let daysAgo: Double = 2
        let timeAgo = Date().addingTimeInterval(-daysAgo * 24 * 60 * 60)
        if upgradeDate <= timeAgo {
            return .plusUpgraded
        }

        return nil
    }
}

// MARK: - Presentation Timing

private struct PendingSurvey {
    let event: SurveyTriggerEvent
    let skipEligibility: Bool
}

/// The same values the Android app uses
private enum PresentationTiming {
    /// How long the app has to be open before the survey can be shown
    static let delayAfterAppOpened: TimeInterval = 3

    /// How long the screen has to go untouched before the survey can be shown
    static let quietPeriodAfterTouch: TimeInterval = 2

    /// How long to wait before checking again when the survey would have interrupted
    static let retryInterval: TimeInterval = 5
}

// MARK: - Survey Check Result

enum SurveyCheckResult {
    case canShow
    case userLeftReview
    case shownRecently
    case userDeclinedRecently
    case wrongUserType
    case deferredEvent // For event types that should be prompted later based on another event

    var displayReason: String {
        switch self {
        case .canShow:
            return "Can show survey"
        case .userLeftReview:
            return "User has already left a review"
        case .shownRecently:
            return "Survey shown recently (within 30 days)"
        case .userDeclinedRecently:
            return "User declined recently (within 60 days)"
        case .wrongUserType:
            return "Event not applicable for user type"
        case .deferredEvent:
            return "Deferred waiting for future event"
        }
    }

    var canShow: Bool {
        switch self {
        case .canShow:
            true
        default:
            false
        }
    }
}

// MARK: - Survey Trigger Events

enum SurveyTriggerEvent: String, CaseIterable {
    // Free user events
    case thirdEpisodeCompleted = "third_episode_completed"
    case episodeStarred = "episode_starred"
    case showRated = "show_rated"
    case filterCreated = "filter_created"

    // Plus user events
    case plusUpgraded = "plus_upgraded"
    case folderCreated = "folder_created"
    case bookmarkCreated = "bookmark_created"
    case customThemeSet = "custom_theme_set"
    case referralShared = "referral_shared"

    // Shared events
    case endOfYearStoryShared = "end_of_year_story_shared"
    case endOfYearCompleted = "end_of_year_completed"
}

private extension SurveyTriggerEvent {
    func shouldShowAnalytics(for event: String, properties: [String: Sendable]) -> Bool {
        switch self {
        case .endOfYearStoryShared, .endOfYearCompleted:
            if AnalyticsEvent.endOfYearStoriesDismissed.eventName == event {
                return true
            }
            return false
        default:
            return false
        }
    }
}
