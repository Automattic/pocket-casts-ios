import Foundation
import AppIntents

struct ExtendSleepTimer: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJExtendSleepTimerIntent"

    static var title: LocalizedStringResource = "Extend Sleep Timer"
    static var description = IntentDescription("Extend Sleep Timer")

    @Parameter(title: "")
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$minutes
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$minutes)) { minutes in
            DisplayRepresentation(
                title: "Extend Sleep Timer by 5 mins",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        let minutes = minutes
        if let minutes = minutes {
            userActivity.title = "Extending sleep timer by \(minutes) minutes"
        } else {
            userActivity.title = "Extend sleep timer"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Extend sleep timer"
        userActivity.becomeCurrent()

        if let minutes = minutes {
            _ = SiriShortcutsManager.shared.extendSleepTimer(addTime: minutes)
        }

        return .result()
    }
}
