import SwiftUI
import AVFoundation
import UIKit
import PocketCastsUtils

protocol AnimatableContent: View {
    func update(for progress: Double)
}

@available(iOS 16, *)
enum VideoExporter {

    struct Parameters {
        let duration: TimeInterval
        let size: CGSize
        let scale: CGFloat
        let fps: Int = 60
        let episodeAsset: AVAsset
        let audioStartTime: CMTime
        let audioDuration: CMTime
        let additionalLoadingCount: Int64 = 50
        let fileType: AVFileType
    }

    enum ExportError: Error {
        case failedToCreateCompositionTrack
        case failedToCreateExportSession
        case failedToAddAudioTrack
        case exportFailed(Error?)
        case taskCancelled
    }

    @MainActor
    static func export<Content: AnimatableContent>(view: Content, with parameters: Parameters, to outputURL: URL, progress: Progress) async throws {
        let loopDuration: Double = 5
        let loopFrameCount = Int(loopDuration * Double(parameters.fps))

        let start = Date()
        FileLog.shared.addMessage("VideoExporter Started: \(start)")

        let temporaryFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(UTType(parameters.fileType.rawValue)?.preferredFilenameExtension ?? ".mp4")

        try await withTaskCancellationHandler {
            let initialExportProgress = Progress(totalUnitCount: Int64(loopFrameCount), parent: progress, pendingUnitCount: 60)
            // Export initial seconds long video
            try await exportInitialVideo(of: view, to: temporaryFileURL, with: parameters, frameCount: loopFrameCount, progress: initialExportProgress)
            FileLog.shared.addMessage("VideoExporter Initial Video Ended: \(start.timeIntervalSinceNow)")

            let compositionProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 10)
            // Create & export final composition at full length by concatenating seconds long video from above until duration
            let composition = try await createFinalComposition(from: temporaryFileURL, with: parameters, to: outputURL, progress: compositionProgress)

            let exportProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 30)
            try await exportFinalComposition(composition, to: outputURL, duration: parameters.duration, fileType: parameters.fileType, progress: exportProgress)

            // Clean up temporary file
            try? FileManager.default.removeItem(at: temporaryFileURL)
            FileLog.shared.addMessage("VideoExporter Ended: \(start.timeIntervalSinceNow)")
        } onCancel: {
            progress.cancel()
        }
    }

    // MARK: - Private Methods

    // Step 1 of video export
    private static func exportInitialVideo<Content: AnimatableContent>(of view: Content, to outputURL: URL, with parameters: Parameters, frameCount: Int, progress: Progress) async throws {
        let videoSize = CGSize(width: parameters.size.width * parameters.scale, height: parameters.size.height * parameters.scale)
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: parameters.fileType)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
        ]
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)

        videoWriter.add(videoWriterInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)

        try await withTaskCancellationHandler {
            try await writeFrames(of: view,
                                  size: parameters.size,
                                  scale: parameters.scale,
                                  fps: parameters.fps,
                                  videoWriterInput: videoWriterInput,
                                  videoWriter: videoWriter,
                                  adaptor: adaptor,
                                  progress: progress,
                                  frameCount: frameCount)
        } onCancel: {
            videoWriter.cancelWriting()
        }
    }

    // Part of Step 1
    private static func writeFrames<Content: AnimatableContent>(of view: Content, size: CGSize, scale: CGFloat, fps: Int, videoWriterInput: AVAssetWriterInput, videoWriter: AVAssetWriter, adaptor: AVAssetWriterInputPixelBufferAdaptor, progress: Progress, frameCount: Int) async throws {
        let counter = Counter()
        try await videoWriterInput.unsafeRequestMediaDataWhenReady {
            while await counter.count <= frameCount, videoWriterInput.isReadyForMoreMediaData {
                guard videoWriter.status != .cancelled else {
                    throw ExportError.taskCancelled
                }

                let frameProgress = Double(await counter.count) / Double(frameCount)
                view.update(for: frameProgress)

                let buffer = try await self.pixelBuffer(for: view, size: size, scale: scale, with: adaptor)
                let frameTime = CMTime(seconds: Double(await counter.count) / Double(fps), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                if videoWriterInput.isReadyForMoreMediaData {
                    adaptor.append(buffer.wrappedValue, withPresentationTime: frameTime)
                    progress.completedUnitCount += 1

                    await counter.increment()
                }
            }

            if await counter.count >= frameCount {
                videoWriterInput.markAsFinished()
                await videoWriter.finishWriting()
                return true
            }

            return false
        }
    }

    @available(iOS 16, *)
    @MainActor
    private static func pixelBuffer(for view: some View, size: CGSize, scale: CGFloat, with adaptor: AVAssetWriterInputPixelBufferAdaptor) throws -> UnsafeTransfer<CVPixelBuffer> {
        try UnsafeTransfer(view.frame(width: size.width, height: size.height).pixelBuffer(size: CGSize(width: size.width * scale, height: size.height * scale), scale: scale))
    }

    // Part 2 of video export, creating the final track from the initial video loop
    private static func createFinalComposition(from sourceURL: URL, with parameters: Parameters, to outputURL: URL, progress: Progress) async throws -> AVComposition {
        guard Task.isCancelled == false else {
            throw ExportError.taskCancelled
        }

        let asset = AVAsset(url: sourceURL)
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let sourceVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.failedToCreateCompositionTrack
        }

        let sourceTimeRange = try await asset.load(.duration)
        let totalDuration = parameters.duration
        var currentTime: CMTime = .zero

        // Set the total unit count for progress reporting
        progress.totalUnitCount = Int64(totalDuration)

        while currentTime < CMTime(seconds: totalDuration, preferredTimescale: 600) {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: sourceTimeRange),
                                                      of: sourceVideoTrack,
                                                      at: currentTime)
            currentTime = CMTimeAdd(currentTime, sourceTimeRange)

            // Update progress
            let completedUnits = Int(currentTime.seconds)
            progress.completedUnitCount = Int64(completedUnits)

            // Check for cancellation
            if Task.isCancelled {
                throw ExportError.taskCancelled
            }
        }

        if let audioTrack = try await parameters.episodeAsset.loadTracks(withMediaType: .audio).first {
            try add(audioTrack: audioTrack, at: CMTimeRange(start: parameters.audioStartTime, duration: parameters.audioDuration), to: composition)
        }

        return composition
    }

    // Part of Step 2 of video export to export the final file
    private static func exportFinalComposition(_ composition: AVComposition, to outputURL: URL, duration: Double, fileType: AVFileType, progress: Progress) async throws {
        guard Task.isCancelled == false else {
            throw ExportError.taskCancelled
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.failedToCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = fileType
        exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))

        let timer = Timer(timeInterval: 0.01, repeats: true) { _ in
            progress.completedUnitCount = Int64(exportSession.progress * 100)
        }
        RunLoop.main.add(timer, forMode: .common)

        await withTaskCancellationHandler {
            await exportSession.export()
        } onCancel: {
            exportSession.cancelExport()
            progress.cancel()
        }

        timer.invalidate()

        guard exportSession.status == .completed else {
            throw ExportError.exportFailed(exportSession.error)
        }
    }

    // Part of Step 2 of video export to add the audio track
    private static func add(audioTrack: AVAssetTrack, at timeRange: CMTimeRange, to composition: AVMutableComposition) throws {
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ExportError.failedToAddAudioTrack
        }
        try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
    }
}

/// Used to safely increment a counter from within an async context
fileprivate actor Counter {
    var count: Int = 0

    func run(block: () async throws -> Void) async throws {
        try await block()
        await increment()
    }

    func increment() async {
        count += 1
    }
}

fileprivate extension AVAssetWriterInput {
    func unsafeRequestMediaDataWhenReady(_ block: @escaping () async throws -> Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            requestMediaDataWhenReady(on: .global(qos: .userInitiated)) {
                _unsafeWait {
                    do {
                        let finished = try await block()
                        if finished {
                            continuation.resume()
                        }
                    } catch {
                        self.markAsFinished()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
