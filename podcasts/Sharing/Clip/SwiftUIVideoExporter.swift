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

        // Add audio input if audioPlayerItem is provided
        var audioWriterInput: AVAssetWriterInput?
        let audioSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        videoWriter.add(audioWriterInput!)

        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)

        let queue = DispatchQueue.main

        let group = DispatchGroup()
        group.enter()

        Task.detached { [weak self] in
            guard let self else { return }

            var buffers: [CVPixelBuffer] = []

            videoWriterInput.requestMediaDataWhenReady(on: queue) { [view, size] in
                progress.totalUnitCount = Int64(frameCount)

                while progress.fractionCompleted < 1 && videoWriterInput.isReadyForMoreMediaData {
                    let frameIndex = Int(progress.completedUnitCount)
                    let loopFrameIndex = frameIndex % loopFrameCount

                    let buffer: CVPixelBuffer?

                    if frameIndex < loopFrameCount {
                        let progress = Double(loopFrameIndex) / Double(loopFrameCount)
                        view.update(for: progress)
                        if #available(iOS 16.0, *) {
                            buffer = self.pixelBuffer(from: view.frame(width: size.width, height: size.height), size: size)
                        } else {
                            let image = view.frame(width: size.width, height: size.height).snapshot()
                            buffer = self.pixelBuffer(from: image)
                        }
                        if let buffer = buffer {
                            buffers.append(buffer)
                        }
                    } else {
                        // After 10 seconds, reuse existing buffers
                        buffer = buffers[loopFrameIndex]
                    }

                    if let buffer = buffer {
                        let frameTime = CMTime(seconds: Double(frameIndex) / Double(self.fps), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        adaptor.append(buffer, withPresentationTime: frameTime)
                        progress.completedUnitCount = Int64(progress.completedUnitCount + 1)
                    }
                }

                if progress.fractionCompleted == 1 {
                    videoWriterInput.markAsFinished()
                    group.leave()
                }
            }

            group.wait()
        }

        // Handle audio export if audioPlayerItem is provided
        if let audioPlayerItem = audioPlayerItem, let audioWriterInput = audioWriterInput {
            group.enter()

            Task.detached {
                var audioReader: AVAssetReader!
                var sharedTrackOutput: AVAssetReaderTrackOutput!

                let tracks = try await audioPlayerItem.asset.load(.tracks)

                let composition = AVMutableComposition()
                guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
                      let sourceAudioTrack = tracks.first else {
                    print("Failed to create audio track")
                    audioWriterInput.markAsFinished()
                    group.leave()
                    return
                }

                let timeRange = CMTimeRangeMake(start: self.audioStartTime, duration: self.audioDuration)
                try compositionAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)

                audioReader = try AVAssetReader(asset: composition)

                let outputSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44100
                ]

                sharedTrackOutput = AVAssetReaderTrackOutput(track: compositionAudioTrack, outputSettings: outputSettings)
                audioReader.add(sharedTrackOutput)
                let isReading = audioReader.startReading()

                audioWriterInput.requestMediaDataWhenReady(on: queue) {
                    guard audioWriterInput.isReadyForMoreMediaData else {
                        audioWriterInput.markAsFinished()
                        group.leave()
                        return
                    }

                    if let sampleBuffer = sharedTrackOutput.copyNextSampleBuffer() {
                        audioWriterInput.append(sampleBuffer)
                    } else {
                        audioWriterInput.markAsFinished()
                        group.leave()
                    }
                }

                group.wait()
            }
        }

        group.notify(queue: queue) {
            videoWriter.finishWriting {
                DispatchQueue.main.async {
                    if videoWriter.status == .completed {
                        completion(.success(()))
                    } else {
                        completion(.failure(ExportError.exportFailed(videoWriter.error)))
                    }
                }
            }
        }
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

        case exportFailed(Error?)
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
