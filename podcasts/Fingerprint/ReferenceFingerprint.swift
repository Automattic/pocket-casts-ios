import Foundation
import PocketCastsUtils

struct ReferenceFingerprint: Codable {
    static let supportedFormat = "fingerprint-compact-v2"

    let format: String
    let totalDuration: Double
    let checkpointInterval: Int
    let checkpointDuration: Int
    let topK: Int
    let timestampQuantum: Int
    let checkpoints: [Checkpoint]

    enum CodingKeys: String, CodingKey {
        case format
        case totalDuration = "total_duration"
        case checkpointInterval = "checkpoint_interval"
        case checkpointDuration = "checkpoint_duration"
        case topK = "top_k"
        case timestampQuantum = "timestamp_quantum"
        case checkpoints
    }

    struct Checkpoint: Codable {
        let delta: Int
        let data: String

        init(delta: Int, data: String) {
            self.delta = delta
            self.data = data
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            delta = try container.decode(Int.self)
            data = try container.decode(String.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(delta)
            try container.encode(data)
        }
    }

    static func decode(from data: Data) -> ReferenceFingerprint? {
        let fingerprint: ReferenceFingerprint
        do {
            fingerprint = try JSONDecoder().decode(ReferenceFingerprint.self, from: data)
        } catch {
            FileLog.shared.addMessage("ReferenceFingerprint: failed to decode JSON: \(error.localizedDescription)")
            return nil
        }

        guard fingerprint.format == supportedFormat else {
            FileLog.shared.addMessage("ReferenceFingerprint: unknown format '\(fingerprint.format)', expected '\(supportedFormat)'")
            return nil
        }

        return fingerprint
    }
}
