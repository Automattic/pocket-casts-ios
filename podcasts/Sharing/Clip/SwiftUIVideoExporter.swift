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

        // Create a temporary file URL for the initial 10-second video
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")

        // Export initial 10-second video
        exportInitialVideo(to: temporaryFileURL, frameCount: loopFrameCount) { result in
            Task {
                switch result {
                case .success:
                    do {
                        // Export final composition at full length
                        try await self.createFinalComposition(from: temporaryFileURL, outputURL: outputURL, progress: progress)
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: temporaryFileURL)
                        completion(.success(()))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func exportInitialVideo(to outputURL: URL, frameCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
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

        var frameIndex = 0

        videoWriterInput.requestMediaDataWhenReady(on: .main) { [weak self] in
            guard let self = self else { return }

            while frameIndex <= frameCount, videoWriterInput.isReadyForMoreMediaData {
                autoreleasepool {
                    do {
                        let progress = Double(frameIndex) / Double(frameCount)
                        self.view.update(for: progress)

                        let buffer: CVPixelBuffer
                        if #available(iOS 16.0, *) {
                            buffer = try self.pixelBuffer(from: self.view.frame(width: self.size.width, height: self.size.height), size: self.size)
                        } else {
                            let image = self.view.frame(width: self.size.width, height: self.size.height).snapshot()
                            buffer = try self.pixelBuffer(from: image)
                        }

                        let frameTime = CMTime(seconds: Double(frameIndex) / Double(self.fps), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        adaptor.append(buffer, withPresentationTime: frameTime)
                        frameIndex += 1
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            }

            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                completion(.success(()))
            }
        }
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

        progress.totalUnitCount = 100

        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? ExportError.unknownError)
                case .cancelled:
                    continuation.resume(throwing: ExportError.exportCancelled)
                default:
                    continuation.resume(throwing: ExportError.unknownError)
                }
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
    func pixelBuffer<V: View>(from view: V, size: CGSize) throws -> CVPixelBuffer {
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
            throw CVPixelBufferError.failedToCreateBuffer(status)
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
            throw CVPixelBufferError.failedToCreateContext
        }

        let renderer = ImageRenderer(content: view)
        renderer.render { size, render in
            render(context)
        }

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }

    enum CVPixelBufferError: Error {
        case failedToCreateBuffer(CVReturn)
        case failedToCreateContext
    }

    private func pixelBuffer(from image: UIImage) throws -> CVPixelBuffer {
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
            throw CVPixelBufferError.failedToCreateBuffer(status)
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
            throw CVPixelBufferError.failedToCreateContext
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
        case failedToAddAudioTrack
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
