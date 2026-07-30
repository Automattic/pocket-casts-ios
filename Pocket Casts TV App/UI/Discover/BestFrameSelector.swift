import AVFoundation
import UIKit

struct FrameCandidate {
    let image: UIImage
    let score: Double
}

enum BestFrameSelector {

    enum SelectorError: Error {
        case invalidDuration
        case noCandidatesGenerated
    }

    /// Samples several timestamps across the asset and returns the best-scoring frame.
    static func bestFrame(
        from asset: AVAsset,
        candidateCount: Int = 3,
        startPercentage: Double = 0.05,
        endPercentage: Double = 0.95
    ) async throws -> UIImage {

        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds > 0 else {
            throw SelectorError.invalidDuration
        }

        // Skip the very start/end (often black, fading, or logos)
        let start = durationSeconds * startPercentage
        let end = durationSeconds * endPercentage
        let step = (end - start) / Double(max(candidateCount - 1, 1))

        let times: [CMTime] = (0..<candidateCount).map {
            CMTime(seconds: start + Double($0) * step, preferredTimescale: 600)
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // Generate + score candidates concurrently.
        let candidates = await withTaskGroup(of: FrameCandidate?.self) { group in
            for time in times {
                group.addTask {
                    await Self.candidate(for: time, using: generator)
                }
            }

            var results: [FrameCandidate] = []
            for await candidate in group {
                if let candidate {
                    results.append(candidate)
                }
            }
            return results
        }

        guard let best = candidates.max(by: { $0.score < $1.score }) else {
            throw SelectorError.noCandidatesGenerated
        }

        return best.image
    }

    /// Generates a single frame at `time` and scores it. Runs off-actor since
    /// AVAssetImageGenerator's async image(at:) is itself concurrency-safe.
    private static func candidate(
        for time: CMTime,
        using generator: AVAssetImageGenerator
    ) async -> FrameCandidate? {
        do {
            let result = try await generator.image(at: time)
            let image = UIImage(cgImage: result.image)
            let score = score(image: image)
            return FrameCandidate(image: image, score: score)
        } catch {
            return nil
        }
    }

    /// Higher score = more "interesting"/usable frame.
    /// Combines: not-blank check, brightness in a good range, and contrast/detail.
    private static func score(image: UIImage) -> Double {
        guard let stats = pixelStats(of: image) else { return -1 }

        // Penalize blank/near-solid-color frames heavily
        if stats.isNearSolidColor {
            return -1
        }

        // Prefer frames that aren't too dark or too blown out
        let brightnessScore = 1.0 - abs(stats.meanBrightness - 0.5) * 2 // peak at 0.5

        // Prefer higher variance (more detail/contrast = less likely blurry or flat)
        let contrastScore = min(stats.stdDevBrightness * 4, 1.0)

        return brightnessScore * 0.4 + contrastScore * 0.6
    }

    private struct PixelStats {
        let meanBrightness: Double     // 0...1
        let stdDevBrightness: Double   // 0...1-ish
        let isNearSolidColor: Bool
    }

    private static func pixelStats(of image: UIImage, sampleSize: Int = 50) -> PixelStats? {
        guard let cgImage = image.cgImage else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        let pixelCount = sampleSize * sampleSize
        var sum = 0.0
        var sumOfSquares = 0.0

        var firstPixel: (UInt8, UInt8, UInt8)?
        var isSolid = true
        let tolerance: Int = 10

        for i in 0..<pixelCount {
            let offset = i * 4
            let r = pixelData[offset]
            let g = pixelData[offset + 1]
            let b = pixelData[offset + 2]

            let brightness = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)) / 255.0
            sum += brightness
            sumOfSquares += brightness * brightness

            if let first = firstPixel {
                if abs(Int(r) - Int(first.0)) > tolerance ||
                   abs(Int(g) - Int(first.1)) > tolerance ||
                   abs(Int(b) - Int(first.2)) > tolerance {
                    isSolid = false
                }
            } else {
                firstPixel = (r, g, b)
            }
        }

        let mean = sum / Double(pixelCount)
        let variance = max(sumOfSquares / Double(pixelCount) - mean * mean, 0)
        let stdDev = sqrt(variance)

        return PixelStats(meanBrightness: mean, stdDevBrightness: stdDev, isNearSolidColor: isSolid)
    }
}
