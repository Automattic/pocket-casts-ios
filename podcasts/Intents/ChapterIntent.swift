import Foundation
import AppIntents

struct ChapterIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {

    static let intentClassName = "SJChapterIntent"

    static var title: LocalizedStringResource = "Skip chapter"
    static var description = IntentDescription("Skip chapter")

    @Parameter(title: "Skip chapter")
    var skipForward: NextPrevious?

    init() {

    }

    init(defaultSkip: NextPrevious) {
        self.skipForward = defaultSkip
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Skip to \(\.$skipForward) chapter")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$skipForward)) { skipForward in
            DisplayRepresentation(
                title: "\(skipForward ?? .next) Chapter",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let skipForward else {
            return .result(dialog: .responseFailure)
        }
        switch skipForward {
            case .next:
                let _ = SiriShortcutsManager.shared.skipToNextChapter()
            case .previous:
                let _ = SiriShortcutsManager.shared.skipToPreviousChapter()
        }
        return .result(dialog: .responseSuccess)
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
