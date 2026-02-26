import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ExtendSleepTimerIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJExtendSleepTimerIntent"

    static var title: LocalizedStringResource = "Extend Sleep Timer"
    static var description = IntentDescription("Extend Sleep Timer")

    @Parameter(title: "Minutes", default: 5)
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Extend sleep timer by \(\.$minutes) minutes")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$minutes)) { minutes in
            DisplayRepresentation(
                title: "Extend sleep timer by 5 minutes",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let _ = SiriShortcutsManager.shared.extendSleepTimer(addTime: minutes)
        return .result()
    }
}
