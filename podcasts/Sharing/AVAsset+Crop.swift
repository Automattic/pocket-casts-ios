import AVFoundation

extension AVAsset {
    enum CropError: Error {
        case failedVideoTrackCreation
        case failedExportSession
    }

    func crop(to size: CGSize) async throws -> URL {
        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw CropError.failedVideoTrackCreation
        }

        let assetTrack = try await loadTracks(withMediaType: .video)[0]
        try compositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: assetTrack, at: .zero)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = size
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: duration)

        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)

        let assetTrackSize = try await assetTrack.load(.naturalSize)

        // Calculate the offset to center the video
        let xOffset = (assetTrackSize.width - size.width) / 2
        let yOffset = (assetTrackSize.height - size.height) / 2

        // Create a transform that moves the video to center it in the frame
        let transform = CGAffineTransform(translationX: -xOffset, y: -yOffset)

        transformer.setTransform(transform, at: .zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]

        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw CropError.failedExportSession
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("PCiOS-Cropped-share-\(UUID().uuidString)").appendingPathExtension(for: .mpeg4Movie)
        export.videoComposition = videoComposition
        export.outputURL = outputURL
        export.outputFileType = .mp4

        await export.export()

        return outputURL
    }
}
