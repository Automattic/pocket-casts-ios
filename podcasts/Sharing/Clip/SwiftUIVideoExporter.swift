import SwiftUI
import AVFoundation
import UIKit

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

    @MainActor func exportToMP4(outputURL: URL, progress: Progress) async throws {
        try await withCheckedThrowingContinuation { continuation in
            exportToMP4(outputURL: outputURL, progress: progress, completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    @MainActor func exportToMP4(outputURL: URL, progress: Progress, completion: @escaping (Result<Void, Error>) -> Void) {
        let frameCount = Int(duration * Double(fps))
        let loopDuration: Double = 10
        let loopFrameCount = Int(loopDuration * Double(fps))

        let start = Date()
        print("SwiftUIVideoExporter Started: \(start)")

        // Create AVMutableComposition
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(ExportError.failedToCreateCompositionTrack))
            return
        }

        // Create AVAssetExportSession
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(ExportError.failedToCreateExportSession))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        // Create a temporary file URL for the initial 10-second video
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

        // Export initial 10-second video
        exportInitialVideo(to: temporaryFileURL, loopFrameCount: loopFrameCount) { result in
            switch result {
            case .success:
                print("SwiftUIVideoExporter Video Loop Ended: \(start.timeIntervalSinceNow)")
                // Add the initial video to the composition and scale it
                Task {
                    do {
                        let asset = AVAsset(url: temporaryFileURL)
                        let assetTrack = try await asset.loadTracks(withMediaType: .video).first!
                        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: loopDuration, preferredTimescale: 600))
                        try videoTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
                        videoTrack.scaleTimeRange(CMTimeRange(start: .zero, end: videoTrack.timeRange.end), toDuration: CMTime(seconds: self.duration, preferredTimescale: 600))

                        // Handle audio if provided
                        if let audioPlayerItem = self.audioPlayerItem,
                           let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                            self.add(audioTrack: assetTrack, to: composition, from: audioPlayerItem)
                        }

                        print("SwiftUIVideoExporter Audio Track Added: \(start.timeIntervalSinceNow)")

                        // Export the final composition
                        self.exportFinalComposition(exportSession: exportSession, progress: progress) { exportResult in
                            // Clean up temporary file
                            try? FileManager.default.removeItem(at: temporaryFileURL)

                            switch exportResult {
                            case .success:
                                print("SwiftUIVideoExporter Video Export Ended: \(start.timeIntervalSinceNow)")
                                completion(.success(()))
                            case .failure(let error):
                                print("SwiftUIVideoExporter Video Export Failed: \(start.timeIntervalSinceNow) error: \(error)")
                                completion(.failure(error))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func exportInitialVideo(to outputURL: URL, loopFrameCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(.failure(ExportError.failedToCreateAssetWriter))
            return
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

        videoWriterInput.requestMediaDataWhenReady(on: .main) { [weak self] in
            guard let self = self else { return }

            for frameIndex in 0..<loopFrameCount {
                autoreleasepool {
                    let progress = Double(frameIndex) / Double(loopFrameCount)
                    self.view.update(for: progress)

                    let buffer: CVPixelBuffer?
                    if #available(iOS 16.0, *) {
                        buffer = self.pixelBuffer(from: self.view.frame(width: self.size.width, height: self.size.height), size: self.size)
                    } else {
                        let image = self.view.frame(width: self.size.width, height: self.size.height).snapshot()
                        buffer = self.pixelBuffer(from: image)
                    }

                    if let buffer = buffer {
                        let frameTime = CMTime(seconds: Double(frameIndex) / Double(self.fps), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        adaptor.append(buffer, withPresentationTime: frameTime)
                    }
                }
            }

            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                completion(.success(()))
            }
        }
    }

    private func add(audioTrack: AVAssetTrack, to composition: AVMutableComposition, from audioPlayerItem: AVPlayerItem) {
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)) else {
            print("Failed to create audio track")
            return
        }

        do {
            let timeRange = CMTimeRangeMake(start: audioStartTime, duration: audioDuration)
            try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        } catch {
            print("Failed to insert audio track: \(error)")
        }
    }

    private func exportFinalComposition(exportSession: AVAssetExportSession, progress: Progress, completion: @escaping (Result<Void, Error>) -> Void) {
        progress.totalUnitCount = 100

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(()))
            case .failed:
                completion(.failure(exportSession.error ?? ExportError.unknownError))
            case .cancelled:
                completion(.failure(ExportError.exportCancelled))
            default:
                completion(.failure(ExportError.unknownError))
            }
        }

        // Update progress
        let timer = Timer(timeInterval: 0.1, repeats: true) { timer in
            progress.completedUnitCount = Int64(exportSession.progress * 100)
            if exportSession.status != .exporting {
                timer.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    @MainActor @available(iOS 16.0, *)
    func pixelBuffer<V: View>(from view: V, size: CGSize) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }

        let renderer = ImageRenderer(content: view)
        renderer.render { size, render in
            render(context)
        }

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }

    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }

    enum ExportError: Error {
        case failedToCreateAssetWriter
        case failedToCreateCompositionTrack
        case failedToCreateExportSession
        case exportFailed(Error?)
        case exportCancelled
        case unknownError
    }
}

extension AVAssetWriterInput {
    func fillMediaData(output: AVAssetReaderOutput) async {
        for await _ in requestMediaDataWhenReady(on: DispatchQueue.main) {
            guard let sampleBuffer = output.copyNextSampleBuffer()
            else {
                return
            }

            if isReadyForMoreMediaData {
                append(sampleBuffer)
            }
        }
    }

    func requestMediaDataWhenReady(on queue: DispatchQueue) -> AsyncStream<Void> {
        AsyncStream { continuation in
            requestMediaDataWhenReady(on: queue, using: {
                continuation.yield()
            })

            continuation.onTermination = { @Sendable [weak self] _ in
                self?.markAsFinished()
            }
        }
    }
}
