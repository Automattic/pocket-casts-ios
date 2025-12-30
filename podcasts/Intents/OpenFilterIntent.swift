import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OpenFilterIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJOpenFilterIntent"

    static var title: LocalizedStringResource = "Open Filter"
    static var description = IntentDescription("Open Filter")

    @Parameter(title: "")
    var filterUuid: String?

    @Parameter(title: "")
    var filterName: String?

    static var parameterSummary: some ParameterSummary {
        Summary()
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$filterUuid, \.$filterName)) { filterUuid, filterName in
            DisplayRepresentation(
                title: "Open \(filterName!) Filter",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}
