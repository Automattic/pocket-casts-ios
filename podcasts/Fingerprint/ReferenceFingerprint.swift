import Foundation
import Fingerprint
import PocketCastsUtils

struct ReferenceFingerprint: Decodable {
    static let supportedFormat = "fingerprint-compact-v2"

    let format: String
    let totalDuration: Double
    let checkpointInterval: Int
    let checkpointDuration: Int
    let timestampQuantum: Int
    let checkpoints: [Checkpoint]

    enum CodingKeys: String, CodingKey {
        case format
        case totalDuration = "total_duration"
        case checkpointInterval = "checkpoint_interval"
        case checkpointDuration = "checkpoint_duration"
        case timestampQuantum = "timestamp_quantum"
        case checkpoints
    }

    struct Checkpoint: Decodable {
        let delta: Int
        let data: String

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            delta = try container.decode(Int.self)
            data = try container.decode(String.self)
        }
    }

    struct LibraryCheckpoint {
        let timestampSeconds: Float
        let hashes: [UInt32]
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

    /// Decode every v2 checkpoint into the library's `(timestamp, hashes)` shape.
    /// Returns an empty array if none of the checkpoints parse.
    func libraryCheckpoints() -> [LibraryCheckpoint] {
        var accumulated = 0
        var result: [LibraryCheckpoint] = []
        result.reserveCapacity(checkpoints.count)

        for checkpoint in checkpoints {
            accumulated += checkpoint.delta
            guard let payload = Data(base64Encoded: checkpoint.data) else { continue }
            guard let decoded = fingerprintFromBytes(data: payload) else { continue }
            let timestamp = Float(Double(accumulated) * Double(timestampQuantum) / 1000.0)
            result.append(LibraryCheckpoint(timestampSeconds: timestamp, hashes: decoded.hashes))
        }
        return result
    }

    var checkpointDurationSeconds: Float {
        Float(checkpointDuration)
    }
}
