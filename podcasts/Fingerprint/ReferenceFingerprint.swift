import Foundation
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
    ///
    /// The `data` payload in compact-v2 is the raw little-endian byte packing of
    /// `[UInt32]` hashes (not the `fingerprintFromBytes` framed format), and
    /// `timestampQuantum` is the number of seconds per delta unit (so the resulting
    /// timestamp is `accumulated * quantum` seconds — no /1000 conversion).
    /// Returns an empty array if none of the checkpoints parse.
    func libraryCheckpoints() -> [LibraryCheckpoint] {
        var accumulated = 0
        var result: [LibraryCheckpoint] = []
        result.reserveCapacity(checkpoints.count)

        for checkpoint in checkpoints {
            accumulated += checkpoint.delta
            guard let payload = Data(base64Encoded: checkpoint.data) else { continue }
            guard payload.count % 4 == 0 else { continue }
            // Decode as little-endian UInt32s via byte-shift arithmetic — `Data`'s
            // underlying storage isn't guaranteed to be 4-byte aligned, so directly
            // binding/reinterpreting as `UInt32` can trap on misaligned access.
            let count = payload.count / 4
            var hashes = [UInt32](repeating: 0, count: count)
            payload.withUnsafeBytes { rawBuffer in
                guard let base = rawBuffer.baseAddress else { return }
                for i in 0..<count {
                    let b0 = UInt32(base.load(fromByteOffset: i * 4, as: UInt8.self))
                    let b1 = UInt32(base.load(fromByteOffset: i * 4 + 1, as: UInt8.self))
                    let b2 = UInt32(base.load(fromByteOffset: i * 4 + 2, as: UInt8.self))
                    let b3 = UInt32(base.load(fromByteOffset: i * 4 + 3, as: UInt8.self))
                    hashes[i] = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
                }
            }
            let timestamp = Float(accumulated) * Float(timestampQuantum)
            result.append(LibraryCheckpoint(timestampSeconds: timestamp, hashes: hashes))
        }
        return result
    }

    var checkpointDurationSeconds: Float {
        Float(checkpointDuration)
    }
}
