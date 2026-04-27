import CryptoKit
import Foundation
import PocketCastsUtils

/// Persists the committed playback↔reference time mapping next to the audio
/// file on disk so that re-opening a transcript for a previously-fingerprinted
/// downloaded episode skips the expensive audio decode + match pipeline.
///
/// The cache is keyed by audio path and validated against a SHA-256 of the
/// reference fingerprint bytes — if the server ships a new reference for the
/// episode, the stale mapping is discarded on load.
enum FingerprintMappingCache {

    private struct CachedMapping: Codable {
        let referenceHash: String
        let entries: [CachedEntry]

        struct CachedEntry: Codable {
            let p: Double
            let r: Double
            let s: Float
        }
    }

    static func load(
        audioFilePath: String,
        referenceData: Data
    ) -> [FingerprintTimingManager.TimeMappingEntry]? {
        let path = mappingPath(forAudioFilePath: audioFilePath)
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        guard let cached = try? JSONDecoder().decode(CachedMapping.self, from: data) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: failed to decode cache at \(path) — discarding"
            )
            return nil
        }
        let currentHash = sha256(referenceData)
        guard cached.referenceHash == currentHash else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: reference hash mismatch at \(path) — discarding"
            )
            return nil
        }
        FileLog.shared.addMessage(
            "FingerprintMappingCache: loaded \(cached.entries.count) cached mappings from \(path)"
        )
        return cached.entries.map {
            FingerprintTimingManager.TimeMappingEntry(
                playbackTime: $0.p,
                referenceTime: $0.r,
                score: $0.s
            )
        }
    }

    static func save(
        _ entries: [FingerprintTimingManager.TimeMappingEntry],
        audioFilePath: String,
        referenceData: Data
    ) {
        guard !entries.isEmpty else { return }
        let path = mappingPath(forAudioFilePath: audioFilePath)
        let cached = CachedMapping(
            referenceHash: sha256(referenceData),
            entries: entries.map {
                CachedMapping.CachedEntry(p: $0.playbackTime, r: $0.referenceTime, s: $0.score)
            }
        )
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            FileLog.shared.addMessage(
                "FingerprintMappingCache: saved \(entries.count) mappings to \(path)"
            )
        } catch {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: failed to save to \(path) — \(error.localizedDescription)"
            )
        }
    }

    static func mappingPath(forAudioFilePath audioPath: String) -> String {
        (audioPath as NSString).deletingPathExtension + ".map.fp.json"
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
