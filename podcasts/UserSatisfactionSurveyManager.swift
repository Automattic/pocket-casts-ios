import Foundation
import PocketCastsServer
import SwiftUI
import PocketCastsUtils

public class UserSatisfactionSurveyManager {
    public static let shared = UserSatisfactionSurveyManager()

    private init() {}

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
        case .firstEpisodeCompleted, .thirdEpisodeCompleted, .episodeStarred, .showRated, .filterCreated:
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

        let surveyView = UserSatisfactionSurveyView(presentSupportView: {
            EmailHelper().presentSupportDialog(source, type: .satisfactionSurvey)
        })
        let hostingController = ThemedHostingController(rootView: surveyView, background: \.primaryUi01)

        // Let the hosting controller size itself
        hostingController.sizingOptions = .intrinsicContentSize

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

    private func presentSupportView(from viewController: UIViewController) {
        // Present support/help view
        // This would typically navigate to the help/support section
        // For now, we'll just dismiss the current view
        viewController.dismiss(animated: true)
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
    case firstEpisodeCompleted = "first_episode_completed"
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

// MARK: - Survey Event Tracker

public class SurveyEventTracker {
    public static let shared = SurveyEventTracker()

    var episodeCompletionCount: Int {
        get { UserDefaults.standard.integer(forKey: "surveyEpisodeCompletionCount") }
        set { UserDefaults.standard.set(newValue, forKey: "surveyEpisodeCompletionCount") }
    }

    private var plusUpgradeDate: Date? {
        get { UserDefaults.standard.object(forKey: "surveyPlusUpgradeDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "surveyPlusUpgradeDate") }
    }

    private init() {}

    // MARK: - Event Tracking Methods

    @MainActor public func trackEpisodeCompleted() {
        episodeCompletionCount += 1

        // Check for first episode completion
        if episodeCompletionCount == 1 {
            checkAndTriggerSurvey(for: .firstEpisodeCompleted)
        }
        // Check for third episode completion
        else if episodeCompletionCount == 3 {
            checkAndTriggerSurvey(for: .thirdEpisodeCompleted)
        }
    }

    @MainActor public func trackEpisodeStarred() {
        checkAndTriggerSurvey(for: .episodeStarred)
    }

    @MainActor public func trackShowRated() {
        checkAndTriggerSurvey(for: .showRated)
    }

    @MainActor public func trackFilterCreated() {
        checkAndTriggerSurvey(for: .filterCreated)
    }

    public func trackPlusUpgrade() {
        plusUpgradeDate = Date()
    }

    @MainActor public func trackFolderCreated() {
        checkAndTriggerSurvey(for: .folderCreated)
    }

    @MainActor public func trackBookmarkCreated() {
        checkAndTriggerSurvey(for: .bookmarkCreated)
    }

    @MainActor public func trackCustomThemeSet() {
        checkAndTriggerSurvey(for: .customThemeSet)
    }

    @MainActor public func trackReferralShared() {
        checkAndTriggerSurvey(for: .referralShared)
    }

    // MARK: - Helper Methods

    /// Call this method during app launch or lifecycle events to check for eligible plus upgrade surveys
    @MainActor public func checkPlusUpgradeSurveyEligibility() {
        guard let upgradeDate = plusUpgradeDate else { return }

        let daysAgo: Double = 2
        let timeAgo = Date().addingTimeInterval(-daysAgo * 24 * 60 * 60)
        if upgradeDate <= timeAgo {
            checkAndTriggerSurvey(for: .plusUpgraded)
        }
    }

    @MainActor private func checkAndTriggerSurvey(for event: SurveyTriggerEvent) {
        guard let topViewController = UIApplication.shared.topViewController else { return }

        if UserSatisfactionSurveyManager.shared.shouldShowSurvey(for: event) {
            UserSatisfactionSurveyManager.shared.presentSurvey(from: topViewController, event: event)
        }
    }
}

// MARK: - UIApplication Extension

extension UIApplication {
    @MainActor var topViewController: UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }

        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}
