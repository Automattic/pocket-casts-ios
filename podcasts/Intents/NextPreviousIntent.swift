import Foundation
import AppIntents

enum NextPrevious: String, AppEnum {
    case next
    case previous

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Skip Chapter")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .next: "Next",
        .previous: "Previous"
    ]
}
