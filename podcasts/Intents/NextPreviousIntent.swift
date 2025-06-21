import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum NextPrevious: String, AppEnum {
    case next
    case previous

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Skip Chapter")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .next: "Next",
        .previous: "Previous"
    ]
}

