import CryptoKit
import Foundation
import PocketCastsUtils

/// Persists the committed playback↔reference time mapping next to the audio
/// file on disk so that re-opening a transcript for a previously-fingerprinted
/// downloaded episode skips the audio decode + match pipeline entirely.
///
/// The cache is *all-or-nothing*: it's loaded only when the cached mapping
/// covers (by `fullCoverageThreshold`) the whole reference timeline, the
/// reference fingerprint bytes hash to the same value, and the underlying
/// audio file's size+mtime are unchanged. Anything less and the cache is
/// ignored — partial-cache short-circuits are how the prior POC-546 attempt
/// trapped the timing manager in `.preparing`.
enum FingerprintMappingCache {

    struct LoadResult {
        let entries: [FingerprintTimingManager.TimeMappingEntry]
        let referenceDuration: Double
    }

    private struct CachedMapping: Codable {
        let schemaVersion: Int
        let referenceHash: String
        let audioByteSize: UInt64
        let audioMTime: Double
        let referenceDuration: Double
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
    ) -> LoadResult? {
        let path = mappingPath(forAudioFilePath: audioFilePath)
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        guard let cached = try? JSONDecoder().decode(CachedMapping.self, from: data) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: failed to decode cache at \(path) — discarding"
            )
            return nil
        }
        guard cached.schemaVersion == FingerprintConstants.mappingCacheSchemaVersion else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: schema version mismatch at \(path) — discarding"
            )
            return nil
        }
        guard cached.referenceHash == sha256(referenceData) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: reference hash mismatch at \(path) — discarding"
            )
            return nil
        }
        guard let attrs = audioAttributes(at: audioFilePath),
              attrs.size == cached.audioByteSize,
              abs(attrs.mtime - cached.audioMTime) < 1.0 else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: audio file changed at \(audioFilePath) — discarding cache"
            )
            return nil
        }
        guard let last = cached.entries.last,
              cached.referenceDuration > 0,
              last.r / cached.referenceDuration >= FingerprintConstants.fullCoverageThreshold else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: partial coverage at \(path) — ignoring (will run full stream)"
            )
            return nil
        }
        FileLog.shared.addMessage(
            "FingerprintMappingCache: loaded \(cached.entries.count) cached mappings from \(path)"
        )
        return LoadResult(
            entries: cached.entries.map {
                FingerprintTimingManager.TimeMappingEntry(
                    playbackTime: $0.p,
                    referenceTime: $0.r,
                    score: $0.s
                )
            },
            referenceDuration: cached.referenceDuration
        )
    }

    static func save(
        _ entries: [FingerprintTimingManager.TimeMappingEntry],
        audioFilePath: String,
        referenceData: Data,
        referenceDuration: Double
    ) {
        guard let last = entries.last,
              referenceDuration > 0,
              last.referenceTime / referenceDuration >= FingerprintConstants.fullCoverageThreshold else {
            return
        }
        guard let attrs = audioAttributes(at: audioFilePath) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: cannot stat audio at \(audioFilePath) — skipping save"
            )
            return
        }
        let path = mappingPath(forAudioFilePath: audioFilePath)
        let cached = CachedMapping(
            schemaVersion: FingerprintConstants.mappingCacheSchemaVersion,
            referenceHash: sha256(referenceData),
            audioByteSize: attrs.size,
            audioMTime: attrs.mtime,
            referenceDuration: referenceDuration,
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

    private static func audioAttributes(at path: String) -> (size: UInt64, mtime: Double)? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        let size = (attrs[.size] as? NSNumber)?.uint64Value ?? 0
        let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? 0
        guard size > 0, mtime > 0 else { return nil }
        return (size, mtime)
    }
}
