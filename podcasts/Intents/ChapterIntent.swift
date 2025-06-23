import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
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
//        IntentPrediction(parameters: ()) {  in
//            DisplayRepresentation(
//                title: "",
//                subtitle: ""
//            )
//        }
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

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
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

