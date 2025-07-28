import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsUtils
import StoreKit

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

    // MARK: - Survey Entry Points

    /// Checks if the survey should be shown based on the event and user context
    func shouldShowSurvey(for event: SurveyTriggerEvent) -> Bool {
        let result = checkSurveyEligibility(for: event)
        FileLog.shared.addMessage("UserSatisfactionSurveyManager: Should show survey for \(event.rawValue): \(result.displayReason)")
        return result == .canShow
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
        }
    }

    /// Presents the survey view
    func presentSurvey(from viewController: UIViewController, event: SurveyTriggerEvent, skipCheck: Bool = false) {
        guard shouldShowSurvey(for: event) || skipCheck else { return }

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
        if !skipCheck {
            Settings.addSurveyPresented()
        }
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
    public func track(name: String, properties: [AnyHashable: Any]?) {
        guard let analyticsEvent = mapAnalyticsEventToSurveyTrigger(name: name) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }

            if self.shouldShowSurvey(for: analyticsEvent) {
                guard let topViewController = SceneHelper.rootViewController() else { return }
                self.presentSurvey(from: topViewController, event: analyticsEvent)
            }
        }
    }

    private func mapAnalyticsEventToSurveyTrigger(name: String) -> SurveyTriggerEvent? {
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
        default:
            return nil
        }
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

// MARK: - Survey Check Result

enum SurveyCheckResult {
    case canShow
    case userLeftReview
    case shownRecently
    case userDeclinedRecently
    case wrongUserType

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
}
