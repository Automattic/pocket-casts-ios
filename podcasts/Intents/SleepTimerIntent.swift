import Foundation
import AppIntents

struct SleepTimer: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJSleepTimerIntent"

    static var title: LocalizedStringResource = "Sleep Timer"
    static var description = IntentDescription("Set Sleep Timer")

    @Parameter(title: "")
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary()
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$minutes)) { minutes in
            DisplayRepresentation(
                title: "Set sleep timer",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let minutes {
            userActivity.title = "Setting sleep timer to \(minutes) minutes"
        } else {
            userActivity.title = "Setting sleep timer"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Set sleep timer"
        userActivity.becomeCurrent()

        if let minutes = minutes {
            _ = SiriShortcutsManager.shared.sleepTimer(newTime: minutes)
        }

        return .result()

//        let response = SJSleepTimerIntentResponse(code: .continueInApp, userActivity: userActivity)
//        completion(response)
    }
}
