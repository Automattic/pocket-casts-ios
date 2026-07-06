import Foundation

/// Maps a time in the generated-content (reference) timeline onto the played
/// audio file's timeline. In the main app this is implemented by
/// `FingerprintTimingManager`; targets that don't include fingerprinting (App
/// Clip, watchOS, tvOS) simply leave the provider unset, so the adjustment is a
/// no-op there and generated chapters keep their reference times.
protocol ChapterReferenceTimeMapping: AnyObject {
    /// Whether a usable mapping is currently available.
    var hasChapterReferenceMapping: Bool { get }

    /// The played-file time for a time in the reference timeline, or `nil` if it
    /// can't be mapped.
    func playbackTime(forReferenceTime referenceTime: TimeInterval) -> TimeInterval?
}

/// Registered by the app once fingerprint timing is available. Stays `nil` in
/// targets without fingerprinting.
enum ChapterReferenceTimeMappingProvider {
    static var current: ChapterReferenceTimeMapping?
}

#if !os(watchOS) && !APPCLIP && !os(tvOS)
// MARK: - ChapterReferenceTimeMapping
extension FingerprintTimingManager: ChapterReferenceTimeMapping {
    /// A mapping is usable once we've reached `.active` (enough coverage to trust
    /// the reference↔playback interpolation). `playbackTime(forReferenceTime:)`
    /// is already declared above and satisfies the protocol requirement.
    var hasChapterReferenceMapping: Bool {
        if case .active = state {
            return true
        }
        return false
    }
}
#endif
