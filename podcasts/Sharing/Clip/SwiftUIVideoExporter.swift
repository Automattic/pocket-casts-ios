import SwiftUI
import AVFoundation
import UIKit

@available(iOS 16.0, *)
class SwiftUIVideoExporter<Content: View> {
    private let view: Content
    private let duration: TimeInterval
    private let size: CGSize
    private let fps: Int

    init(view: Content, duration: TimeInterval, size: CGSize, fps: Int = 60) {
        self.view = view
        self.duration = duration
        self.size = size
        self.fps = fps
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

        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale

        let queue = DispatchQueue(label: "com.videoexporter.renderqueue")

        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            progress.totalUnitCount = Int64(frameCount)
            (0..<frameCount).forEach { frameNumber in
                if videoWriterInput.isReadyForMoreMediaData {
                    let time = Double(frameNumber) / Double(self.fps)

                    // Update the view for the next frame
                    DispatchQueue.main.sync {
                        if let image = renderer.uiImage {
                            if let buffer = self.pixelBuffer(from: image) {
                                let frameTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                                adaptor.append(buffer, withPresentationTime: frameTime)
                                progress.completedUnitCount = Int64(frameNumber)
                            }
                        }
                    }
                }
            }

            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                DispatchQueue.main.async {
                    switch videoWriter.status {
                    case .failed:
                        completion(.failure(ExportError.exportFailed(videoWriter.error)))
                    case .completed:
                        completion(.success(()))
                    default:
                        ()
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
