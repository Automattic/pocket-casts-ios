import Foundation
import CoreLocation
import AppIntents
import CoreTransferable

@available(iOS 18.0, *)
@AssistantEntity(schema: .journal.entry)
struct TranscriptEntryEntity {
    struct TranscriptEntryEntityQuery: EntityStringQuery {
        func entities(for identifiers: [TranscriptEntryEntity.ID]) async throws -> [TranscriptEntryEntity] { [] }
        func entities(matching string: String) async throws -> [TranscriptEntryEntity] { [] }
    }

    static var defaultQuery = TranscriptEntryEntityQuery()
    var displayRepresentation: DisplayRepresentation { "Transcript Representation" }

    let id = UUID()

    var title: String?
    var message: AttributedString?
    var mediaItems: [IntentFile]
    var entryDate: Date?
    var location: CLPlacemark?

    var entryText: String {
        return NSAttributedString(message ?? "").string
    }
}

@available(iOS 18.0, *)
extension TranscriptEntryEntity: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.entryText)
    }
}

@available(iOS 18.0, *)
extension TranscriptModel {

    var appEntity: TranscriptEntryEntity {
        let entity = TranscriptEntryEntity()
        entity.message = AttributedString(attributedText)
        return entity
    }
}
