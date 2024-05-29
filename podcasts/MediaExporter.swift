import Foundation
import AVFoundation
import PocketCastsUtils

struct MediaExporter {

    #if !os(watchOS)
    static func exportMediaItem(_ item: AVPlayerItem, to outputURL: URL) async -> Bool {
        let composition = AVMutableComposition()

        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
            let sourceAudioTrack = try? await item.asset.loadTracks(withMediaType: .audio).first else {
            FileLog.shared.addMessage("Media Export Session -> Failed to create audio track")
            return false
        }
        do {
            try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: item.asset.duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch {
            FileLog.shared.addMessage("Media Export Session -> Failed to create audio track: \(error)")
            return false
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            FileLog.shared.addMessage("Media Export Session -> Failed to create export session")
            return false
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = AVFileType.m4a

        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch let error {
                FileLog.shared.addMessage("Media Export Session -> Failed to delete file with error: \(error)")
                return false
            }
        }

        await exporter.export()

        if let error = exporter.error {
            FileLog.shared.addMessage("Media Export Session -> Finished with error: \(error)")
            return false
        }

        FileLog.shared.addMessage("Media Export Session -> Finished exporting to: \(outputURL)")
        return true
    }
    #endif
}
