import AVFoundation
import PocketCastsUtils

class AudioClipExporter {
    enum AudioExportError: Error {
        case noAudioTrack
        case failedToInsertTimeRange
        case failedToCreateExportSession
        case exportSessionFailed(Error)
        case cancelledTask
    }

    static func exportAudioClip(from asset: AVAsset, startTime: CMTime, duration: CMTime, to outputURL: URL, progress: Progress) async throws {
        let composition = AVMutableComposition()

        let date = Date()
        FileLog.shared.addMessage("AudioClipExporter Started: \(date)")

        progress.totalUnitCount = 100

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

        let progressObserver = Task {
            while !Task.isCancelled {
                progress.completedUnitCount = Int64(exportSession.progress * 100)
                try await Task.sleep(nanoseconds: 100*1000)
            }
        }

        await withTaskCancellationHandler {
            FileLog.shared.addMessage("AudioClipExporter Started Audio Export: \(date.timeIntervalSinceNow)")
            await exportSession.export()
            FileLog.shared.addMessage("AudioClipExporter Ended Audio Export: \(date.timeIntervalSinceNow)")
        } onCancel: {
            exportSession.cancelExport()
        }

        progressObserver.cancel()

        switch exportSession.status {
        case .completed:
            progress.fileURL = outputURL
            progress.completedUnitCount = 100
            FileLog.shared.addMessage("AudioClipExporter Finished: \(date.timeIntervalSinceNow)")
        case .failed:
            progress.cancel()
            if let error = exportSession.error {
                FileLog.shared.addMessage("AudioClipExporter: Export failed \(error)")
                throw AudioExportError.exportSessionFailed(error)
            }
        case .cancelled:
            progress.cancel()
            throw AudioExportError.cancelledTask
        default:
            FileLog.shared.addMessage("AudioClipExporter: Export ended with status: \(exportSession.status.rawValue)")
        }
    }
}
