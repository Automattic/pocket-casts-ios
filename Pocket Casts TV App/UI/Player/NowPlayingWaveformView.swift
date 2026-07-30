import SwiftUI

struct NowPlayingWaveformView: View {
    let color: Color
    let isAnimating: Bool
    let artworkSize: CGFloat
    let playbackManager: PlaybackManager

    init(color: Color, isAnimating: Bool, artworkSize: CGFloat, playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.color = color
        self.isAnimating = isAnimating
        self.artworkSize = artworkSize
        self.playbackManager = playbackManager
    }
    /// Tracks the time-based envelope fade so Canvas can lerp each frame.
    @State private var fromAmplitude: CGFloat = 0
    @State private var toAmplitude: CGFloat = 0
    @State private var fadeStartTime: Date = .distantPast
    @State private var isActive = false
    /// Once we've seen real audio data from the tap, stay in audio-reactive
    /// mode — don't flip back to sine fallback when the level drops on pause.
    @State private var useAudioReactive = false
    /// Reference type so the Canvas closure can update it every frame
    /// without mutating SwiftUI state.
    @State private var levelSmoother = LevelSmoother()

    private let barWidth: CGFloat = 5
    private let barSpacing: CGFloat = 7
    private let maxBarHeight: CGFloat = 100
    private let fadeDuration: TimeInterval = 2.0

    /// Compute the current envelope amplitude by lerping between fromAmplitude and
    /// toAmplitude using an ease-in-out curve driven by wall-clock time.
    private func envelope(at date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSince(fadeStartTime)
        let t = min(max(elapsed / fadeDuration, 0), 1)
        let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        return fromAmplitude + (toAmplitude - fromAmplitude) * eased
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isActive)) { timeline in
            Canvas { context, size in
                let env = envelope(at: timeline.date)
                guard env > 0.001 else { return }

                // Resolve the dynamic color once per frame; resolving it inside
                // fill(_:with:) would go through the UIKit trait-collection
                // machinery for every bar.
                let shading = context.resolve(.color(color))

                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkHalf = artworkSize / 2

                let sideWidth = (size.width - artworkSize) / 2
                let barsPerSide = Int(sideWidth / (barWidth + barSpacing))

                let time = timeline.date.timeIntervalSinceReferenceDate

                // Poll real audio level from the playback engine (lock-free read).
                // Returns 0 for HLS streams where no audio tap is available.
                // Smoothed with attack/release ballistics so bar heights don't
                // jump between frames.
                let rawAudioLevel = CGFloat(playbackManager.currentAudioLevel)
                let targetLevel = useAudioReactive ? max(rawAudioLevel, 0.05) : 1.0
                let level = levelSmoother.smooth(targetLevel, at: time)

                for side in 0..<2 {
                    for i in 0..<barsPerSide {
                        let normalizedIndex = CGFloat(i) / CGFloat(max(1, barsPerSide - 1))
                        let distanceFactor = side == 0 ? normalizedIndex : (1.0 - normalizedIndex)

                        // Sine wave gives the smooth pulsing shape; scaled by the
                        // smoothed audio level when available, otherwise the sine
                        // alone acts as a pure ambient animation
                        let sineWave = CGFloat(sin(time * 2.5 + Double(i) * 0.4) * 0.5 + 0.5)
                        let height = maxBarHeight * distanceFactor * sineWave * level * env

                        let x: CGFloat
                        if side == 0 {
                            x = centerX - artworkHalf - CGFloat(barsPerSide - i) * (barWidth + barSpacing)
                        } else {
                            x = centerX + artworkHalf + CGFloat(i) * (barWidth + barSpacing) + barSpacing
                        }

                        var path = Path()
                        path.addRoundedRect(
                            in: CGRect(x: x, y: centerY - height / 2, width: barWidth, height: max(2, height)),
                            cornerSize: CGSize(width: 2, height: 2)
                        )
                        context.opacity = 0.8 * Double(distanceFactor) * Double(env)
                        context.fill(path, with: shading)
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .onChange(of: isAnimating) { _, newValue in
            beginFade(to: newValue ? 1 : 0)
        }
        .onAppear {
            if isAnimating {
                beginFade(to: 1)
            }
        }
        .task(id: isAnimating) {
            // Poll for real audio data outside of Canvas (state can't be
            // mutated inside Canvas). Restarts each time playback starts
            // so episode changes (downloaded → HLS) re-detect correctly.
            guard isAnimating else { return }
            while !Task.isCancelled {
                if playbackManager.currentAudioLevel > 0.01 {
                    useAudioReactive = true
                    return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func beginFade(to target: CGFloat) {
        fromAmplitude = envelope(at: Date())
        toAmplitude = target
        fadeStartTime = Date()
        isActive = true
        if target == 1 {
            // Reset so the polling task re-detects audio availability.
            // Handles episode changes (e.g. downloaded → HLS stream).
            useAudioReactive = false
        }
        if target == 0 {
            // Stop the timeline after the fade-out completes
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(fadeDuration + 0.1))
                if toAmplitude == 0 {
                    isActive = false
                }
            }
        }
    }
}

/// Frame-rate-independent attack/release smoothing for the audio level,
/// applied on top of the per-buffer smoothing in the audio tap. Fast attack
/// keeps transients visible; slow release stops per-frame flicker.
private final class LevelSmoother {
    private var value: CGFloat = 0
    private var lastTime: TimeInterval?

    private let attackTimeConstant: TimeInterval = 0.05
    private let releaseTimeConstant: TimeInterval = 0.3

    func smooth(_ target: CGFloat, at time: TimeInterval) -> CGFloat {
        guard let lastTime, time > lastTime else {
            self.lastTime = time
            value = target
            return value
        }
        self.lastTime = time
        let dt = min(time - lastTime, 0.1)
        let timeConstant = target > value ? attackTimeConstant : releaseTimeConstant
        value += (target - value) * (1 - exp(-dt / timeConstant))
        return value
    }
}
