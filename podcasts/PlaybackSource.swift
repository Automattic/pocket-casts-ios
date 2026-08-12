import Foundation
import PocketCastsDataModel

/// The concrete thing the player will open for an episode.
struct PlaybackSource: Equatable {
    enum Kind {
        /// A file on disk: a completed download or a stream-and-cache buffer.
        case localFile
        /// A remote enclosure served as a single file (mp3, m4a, mp4…).
        case progressive
        /// A remote HLS manifest. Segmented, so it exposes no asset tracks and can't be byte-range cached.
        case hls
    }

    struct Options {
        /// Ignore any local copy and resolve the remote source. Used when casting, and when the user
        /// chooses to watch a downloaded episode's video.
        var preferStreaming = false
    }

    let url: URL
    let kind: Kind
}

/// What a source can and can't do. Everything that used to branch on "is this HLS" reads from here,
/// so the differences between the source kinds are stated once.
extension PlaybackSource.Kind {
    /// Whether the source exposes a concrete audio track. HLS manifests don't, which rules out the
    /// `MTAudioProcessingTap` (volume boost, audio levels) and the `AVAudioEngine` pipeline.
    var exposesAudioTracks: Bool {
        self != .hls
    }

    /// Whether the source can carry video that it doesn't declare up front. An HLS manifest exposes no
    /// tracks, so its video only becomes apparent once a frame is decoded. Callers treat it as video from
    /// the start rather than switching the UI over mid-playback.
    var mayCarryUndeclaredVideo: Bool {
        self == .hls
    }

    /// Whether the bytes can be cached to disk while playing (stream-and-cache). HLS is segmented, so
    /// it's streamed directly and never cached.
    var isCacheable: Bool {
        self == .progressive
    }

    /// The highest rate the source can sustain, or `nil` when it isn't capped. HLS can't reliably keep up
    /// past 2x, and the time-domain pitch algorithm degrades past it too.
    var maximumPlaybackSpeed: Double? {
        self == .hls ? 2.0 : nil
    }

    /// Forward buffer to request, or `nil` to leave the `AVPlayer` default in place. HLS gets more
    /// headroom so higher playback rates don't starve the pipeline and stall.
    var preferredForwardBufferDuration: TimeInterval? {
        self == .hls ? 60 : nil
    }

    /// Whether a stall should be recovered by re-applying the rate rather than by `play()`, which
    /// re-seeks to the resume position, flushes the buffer and triggers another stall.
    var recoversFromStallWithoutSeeking: Bool {
        self == .hls
    }

    /// The content type to advertise to external receivers, or `nil` to use the episode's own file type.
    /// An HLS content URL is a manifest, not the progressive file the episode's type describes.
    var advertisedContentType: String? {
        self == .hls ? Episode.advertisedHLSMimeType : nil
    }
}
