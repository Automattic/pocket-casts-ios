import CryptoKit
import Foundation
import PocketCastsUtils

/// Persists the committed playback↔reference time mapping next to the audio
/// file on disk so that re-opening a transcript for a previously-fingerprinted
/// downloaded episode skips the audio decode + match pipeline entirely.
///
/// The cache is *all-or-nothing*: it's loaded only when the cached mapping
/// covers (by `fullCoverageThreshold`) the whole reference timeline, both
/// the reference and audio files' on-disk identity (size+mtime) are
/// unchanged, the reference fingerprint bytes hash to the same value, and
/// a content sample hash of the audio file matches. Anything less and the
/// cache is ignored — partial-cache short-circuits are how the prior
/// POC-546 attempt trapped the timing manager in `.preparing`.
enum FingerprintMappingCache {

    struct LoadResult {
        let entries: [FingerprintTimingManager.TimeMappingEntry]
        let referenceDuration: Double
    }

    private struct CachedMapping: Codable {
        let schemaVersion: Int
        let referenceHash: String
        let referenceByteSize: UInt64
        let referenceMTime: Double
        let audioByteSize: UInt64
        let audioMTime: Double
        let audioContentHash: String
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
        referenceFilePath: String,
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
        guard let refAttrs = fileAttributes(at: referenceFilePath),
              refAttrs.size == cached.referenceByteSize,
              abs(refAttrs.mtime - cached.referenceMTime) < 1.0 else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: reference file changed at \(referenceFilePath) — discarding cache"
            )
            return nil
        }
        guard cached.referenceHash == sha256(referenceData) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: reference hash mismatch at \(path) — discarding"
            )
            return nil
        }
        guard let audioAttrs = fileAttributes(at: audioFilePath),
              audioAttrs.size == cached.audioByteSize,
              abs(audioAttrs.mtime - cached.audioMTime) < 1.0 else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: audio file changed at \(audioFilePath) — discarding cache"
            )
            return nil
        }
        guard contentSampleHash(at: audioFilePath) == cached.audioContentHash else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: audio content hash mismatch at \(audioFilePath) — discarding cache"
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
        referenceFilePath: String,
        referenceData: Data,
        referenceDuration: Double
    ) {
        guard let last = entries.last,
              referenceDuration > 0,
              last.referenceTime / referenceDuration >= FingerprintConstants.fullCoverageThreshold else {
            return
        }
        guard let audioAttrs = fileAttributes(at: audioFilePath) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: cannot stat audio at \(audioFilePath) — skipping save"
            )
            return
        }
        guard let refAttrs = fileAttributes(at: referenceFilePath) else {
            FileLog.shared.addMessage(
                "FingerprintMappingCache: cannot stat reference at \(referenceFilePath) — skipping save"
            )
            return
        }
        let path = mappingPath(forAudioFilePath: audioFilePath)
        let cached = CachedMapping(
            schemaVersion: FingerprintConstants.mappingCacheSchemaVersion,
            referenceHash: sha256(referenceData),
            referenceByteSize: refAttrs.size,
            referenceMTime: refAttrs.mtime,
            audioByteSize: audioAttrs.size,
            audioMTime: audioAttrs.mtime,
            audioContentHash: contentSampleHash(at: audioFilePath) ?? "",
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

    private static func fileAttributes(at path: String) -> (size: UInt64, mtime: Double)? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        let size = (attrs[.size] as? NSNumber)?.uint64Value ?? 0
        let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? 0
        guard size > 0, mtime > 0 else { return nil }
        return (size, mtime)
    }

    private static let contentSampleSize = 65_536

    private static func contentSampleHash(at path: String) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: contentSampleSize)
        guard !data.isEmpty else { return nil }
        return sha256(data)
    }
}
