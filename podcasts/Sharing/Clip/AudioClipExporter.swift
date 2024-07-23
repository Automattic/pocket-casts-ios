import AVFoundation

class AudioClipExporter {
    typealias ProgressCallback = (Float) -> Void

    static func exportAudioClip(from playerItem: AVPlayerItem, startTime: CMTime, duration: CMTime, to outputURL: URL, progressCallback: ProgressCallback? = nil) async -> Bool {
        let composition = AVMutableComposition()

        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
              let tracks = try? await playerItem.asset.loadTracks(withMediaType: .audio),
              let sourceAudioTrack = tracks.first else {
            print("Failed to create audio track")
            return false
        }

        do {
            let timeRange = CMTimeRangeMake(start: startTime, duration: duration)
            try compositionAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)
        } catch {
            print("Failed to insert time range: \(error)")
            return false
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create export session")
            return false
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: duration)

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return true
        case .failed:
            if let error = exportSession.error {
                print("Export failed: \(error)")
            }
            return false
        case .cancelled:
            print("Export cancelled")
            return false
        default:
            print("Export ended with status: \(exportSession.status.rawValue)")
            return false
        }
    }
}

