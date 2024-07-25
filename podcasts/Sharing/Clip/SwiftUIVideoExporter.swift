import SwiftUI
import AVFoundation
import UIKit

class SwiftUIVideoExporter<Content: View> {
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
        if let audioPlayerItem = audioPlayerItem {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            videoWriter.add(audioWriterInput!)
        }

        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)

        let queue = DispatchQueue.main

        let group = DispatchGroup()
        group.enter()

        videoWriterInput.requestMediaDataWhenReady(on: queue) { [view] in
            progress.totalUnitCount = Int64(frameCount)
            for frameNumber in 0..<frameCount {
                if videoWriterInput.isReadyForMoreMediaData {
                    let time = Double(frameNumber) / Double(self.fps)
                    let image = view.snapshot()
                    if let buffer = self.pixelBuffer(from: image) {
                        let frameTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        adaptor.append(buffer, withPresentationTime: frameTime)
                        progress.completedUnitCount = Int64(frameNumber)
                    }
                }
            }

            videoWriterInput.markAsFinished()
            group.leave()
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

//            monitor.quakeHandler = { quake in
//                continuation.yield(quake)
//            }
//            continuation.onTermination = { @Sendable _ in
//                 monitor.stopMonitoring()
//            }
//            monitor.startMonitoring()
        }
    }
}
