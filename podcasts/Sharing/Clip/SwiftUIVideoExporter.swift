import SwiftUI
import AVFoundation
import UIKit
import PocketCastsUtils

protocol AnimatableContent: View {
    func update(for progress: Double)
}

class SwiftUIVideoExporter<Content: AnimatableContent> {
    private let view: Content
    private let duration: TimeInterval
    private let size: CGSize
    private let fps: Int
    private let audioPlayerItem: AVPlayerItem?
    private let audioStartTime: CMTime
    private let audioDuration: CMTime

    init(view: Content, duration: TimeInterval, size: CGSize, fps: Int = 60, audioPlayerItem: AVPlayerItem, audioStartTime: CMTime, audioDuration: CMTime) {
        self.view = view
        self.duration = duration
        self.size = size
        self.fps = fps
        self.audioPlayerItem = audioPlayerItem
        self.audioStartTime = audioStartTime
        self.audioDuration = audioDuration
    }

    @MainActor
    func exportToMP4(outputURL: URL, progress: Progress) async throws {
        let loopDuration: Double = 10
        let loopFrameCount = Int(loopDuration * Double(fps))

        let start = Date()
        FileLog.shared.addMessage("SwiftUIVideoExporter Started: \(start)")

        // Create a temporary file URL for the initial 10-second video
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

        progress.totalUnitCount = Int64(loopFrameCount) + 50

        guard Task.isCancelled == false else {
            progress.cancel()
            return
        }

        // Export initial 10-second video
        try await exportInitialVideo(to: temporaryFileURL, frameCount: loopFrameCount, progress: progress)
        FileLog.shared.addMessage("SwiftUIVideoExporter Initial Video Ended: \(start.timeIntervalSinceNow)")
        guard Task.isCancelled == false else {
            progress.cancel()
            return
        }
        // Export final composition at full length
        try await self.createFinalComposition(from: temporaryFileURL, outputURL: outputURL, progress: progress)
        guard Task.isCancelled == false else {
            progress.cancel()
            return
        }
        // Clean up temporary file
        try? FileManager.default.removeItem(at: temporaryFileURL)
        progress.completedUnitCount = progress.totalUnitCount
        FileLog.shared.addMessage("SwiftUIVideoExporter Ended: \(start.timeIntervalSinceNow)")
    }

    private func exportInitialVideo(to outputURL: URL, frameCount: Int, progress: Progress) async throws {
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw ExportError.failedToCreateAssetWriter
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]

        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)

        videoWriter.add(videoWriterInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)

        try await writeFrames(videoWriterInput: videoWriterInput, videoWriter: videoWriter, adaptor: adaptor, progress: progress, frameCount: frameCount)
    }

    private func writeFrames(videoWriterInput: AVAssetWriterInput, videoWriter: AVAssetWriter, adaptor: AVAssetWriterInputPixelBufferAdaptor, progress: Progress, frameCount: Int) async throws {
        let counter = Counter()

        try await videoWriterInput.unsafeRequestMediaDataWhenReady { [weak self] continuation in
            guard let self else { return }
            guard Task.isCancelled == false else {
                videoWriter.cancelWriting()
                progress.cancel()
                return
            }
            while await counter.count <= frameCount, videoWriterInput.isReadyForMoreMediaData {
                guard Task.isCancelled == false else {
                    videoWriter.cancelWriting()
                    progress.cancel()
                    return
                }
                do {
                    try await counter.run {
                        let frameProgress = Double(await counter.count) / Double(frameCount)
                        self.view.update(for: frameProgress)

                        let buffer: UnsafeTransfer<CVPixelBuffer>

                        buffer = try await self.pixelBuffer(for: self.view, size: self.size)

                        let frameTime = CMTime(seconds: Double(await counter.count) / Double(self.fps), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        adaptor.append(buffer.wrappedValue, withPresentationTime: frameTime)
                        progress.completedUnitCount += 1
                    }
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }

            let frameIndex = await counter.count
            if frameIndex >= frameCount {
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func pixelBuffer(for view: some View, size: CGSize) throws -> UnsafeTransfer<CVPixelBuffer> {
        try UnsafeTransfer(view.frame(width: size.width, height: size.height).pixelBuffer(size: size))
    }

    private func createFinalComposition(from sourceURL: URL, outputURL: URL, progress: Progress) async throws {
        let asset = AVAsset(url: sourceURL)
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let sourceVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.failedToCreateCompositionTrack
        }

        do {
            let sourceTimeRange = try await asset.load(.duration)
            let loopDuration = sourceTimeRange
            var currentTime: CMTime = .zero

            // Add the same loop repeatedly until we reach the duration
            while currentTime < CMTime(seconds: duration, preferredTimescale: 600) {
                try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: loopDuration),
                                                          of: sourceVideoTrack,
                                                          at: currentTime)
                currentTime = CMTimeAdd(currentTime, loopDuration)
            }

            // Add audio if available
            if let audioPlayerItem = audioPlayerItem,
               let audioTrack = try await audioPlayerItem.asset.loadTracks(withMediaType: .audio).first {
                try add(audioTrack: audioTrack, to: composition)
            }

            // Export the final composition
            try await exportFinalComposition(composition: composition, outputURL: outputURL, progress: progress)
        } catch {
            throw error
        }
    }

    private func add(audioTrack: AVAssetTrack, to composition: AVMutableComposition) throws {
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ExportError.failedToAddAudioTrack
        }

        let timeRange = CMTimeRange(start: audioStartTime, duration: audioDuration)
        try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
    }

    private func exportFinalComposition(composition: AVMutableComposition, outputURL: URL, progress: Progress) async throws {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.failedToCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))

        let timer = track(progress: progress, for: exportSession)

        await exportSession.export()

        timer.invalidate()
    }

    private func track(progress: Progress, for exportSession: AVAssetExportSession) -> Timer {
        // Progress updates
        let timer = Timer(timeInterval: 0.05, repeats: true) { timer in
            progress.completedUnitCount = (progress.totalUnitCount - 50) + Int64((50 * exportSession.progress))
            if exportSession.status != .exporting {
                timer.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)

        return timer
    }

    enum ExportError: Error {
        case failedToCreateAssetWriter
        case failedToCreateCompositionTrack
        case failedToCreateExportSession
        case failedToAddAudioTrack
        case exportFailed(Error?)
        case exportCancelled
        case unknownError
    }
}

/// Used to safely increment a counter from within an async context
actor Counter {
    var count: Int = 0

    func run(block: () async throws -> Void) async throws {
        try await block()
        await increment()
    }

    func increment() async {
        count += 1
    }
}

extension AVAssetWriterInput {
    func unsafeRequestMediaDataWhenReady(_ block: @escaping (CheckedContinuation<Void, Error>) async -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            requestMediaDataWhenReady(on: .global(qos: .userInitiated)) { [weak self] in
                _unsafeWait { [weak self] in
                    await block(continuation)
                }
            }
        }
    }
}
