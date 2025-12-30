import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SleepTimerIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJSleepTimerIntent"

    static var title: LocalizedStringResource = "Sleep Timer"
    static var description = IntentDescription("Set Sleep Timer")

    @Parameter(title: "Minutes", default: nil)
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Setting sleep timer to \(\.$minutes) minutes")
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
        var duration: TimeInterval = Settings.customSleepTime()
        if let minutes {
            duration = TimeInterval(minutes).minutes
        }
        let _ = SiriShortcutsManager.shared.sleepTimer(newTime: Int(duration))
        return .result()
    }
}
