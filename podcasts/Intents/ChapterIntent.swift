import Foundation
import AppIntents

struct Chapter: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJChapterIntent"

    static var title: LocalizedStringResource = "Chapter"
    static var description = IntentDescription("Skip chapter")

    @Parameter(title: "Skip chapter", default: .next)
    var skipForward: NextPrevious?

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$skipForward
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$skipForward)) { skipForward in
            DisplayRepresentation(
                title: "\(skipForward!) Chapter",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")
        // TODO: we should really open the app to the episode screen
        // Donate as User Activity
        userActivity.isEligibleForSearch = true
        let direction = skipForward
        userActivity.title = "Skipping to \(direction)"
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "\(direction) chapter"
        userActivity.becomeCurrent()

        if skipForward == .next {
            _ = SiriShortcutsManager.shared.skipToNextChapter()
        } else if skipForward == .previous {
            _ = SiriShortcutsManager.shared.skipToPreviousChapter()
        }

        return .result()
    }
}

fileprivate extension IntentDialog {
    static var responseSuccess: Self {
        "Skipped chapter"
    }
    static var responseFailure: Self {
        "Unable to skip chapter"
    }
    static var responseFailureNoChapters: Self {
        "Podcast doesn't support chapters"
    }
}

