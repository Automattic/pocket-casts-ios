import AVFoundation
import PocketCastsUtils

class AudioClipExporter {
    enum AudioExportError: Error {
        case noAudioTrack
        case failedToInsertTimeRange
        case failedToCreateExportSession
        case exportSessionFailed(Error)
    }

    //TODO: Add Progress reporting
    static func exportAudioClip(from asset: AVAsset, startTime: CMTime, duration: CMTime, to outputURL: URL, progress: Progress) async throws {
        let composition = AVMutableComposition()

        progress.totalUnitCount = 1

        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
              let tracks = try? await asset.loadTracks(withMediaType: .audio),
              let sourceAudioTrack = tracks.first else {
            FileLog.shared.addMessage("AudioClipExporter: Failed to create audio track")
            throw AudioExportError.noAudioTrack
        }

        do {
            let timeRange = CMTimeRangeMake(start: startTime, duration: duration)
            try compositionAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)
        } catch {
            FileLog.shared.addMessage("AudioClipExporter: Failed to insert time range \(error)")
            throw AudioExportError.failedToInsertTimeRange
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            FileLog.shared.addMessage("AudioClipExporter: Failed to create export session")
            throw AudioExportError.failedToInsertTimeRange
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: duration)

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            progress.fileURL = outputURL
            progress.completedUnitCount = 1
        case .failed:
            progress.cancel()
            if let error = exportSession.error {
                FileLog.shared.addMessage("AudioClipExporter: Export failed \(error)")
                throw AudioExportError.exportSessionFailed(error)
            }
        case .cancelled:
            progress.cancel()
        default:
            print("Export ended with status: \(exportSession.status.rawValue)")
//            return false
        }
    }
}
