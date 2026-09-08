import Foundation
import SwiftSubtitles

/// The captions published alongside a What's New video.
struct WhatsNewVideoCaptions {
    private let subtitles: Subtitles

    /// The extension SwiftSubtitles picks its WebVTT parser from.
    private static let format = "vtt"

    init?(data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        self.init(webVTT: text)
    }

    init?(webVTT: String) {
        guard let subtitles = try? Subtitles(content: webVTT, expectedExtension: Self.format), !subtitles.isEmpty else {
            return nil
        }
        self.subtitles = subtitles
    }

    /// What's being said at that point in the video, if anything is.
    func text(at seconds: TimeInterval) -> String? {
        guard seconds.isFinite else { return nil }
        return subtitles.firstCue(containing: seconds)?.text
    }
}
