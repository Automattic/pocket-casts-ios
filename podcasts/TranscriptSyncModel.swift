import Foundation
import Speech

class TranscriptSyncModel {
    static let shared = TranscriptSyncModel()

    var words: [[TimeInterval: String]] = [] {
        didSet {
            print("\n\n\n")
            words.forEach { word in print("\(word.first!.key) \(word.first!.value)") }
            print("\n\n\n")
        }
    }

    func update(_ reference: SFTranscription, offset: TimeInterval) {
        reference.segments.forEach {
            words.append([offset + $0.timestamp: $0.substring])
        }
    }
}
