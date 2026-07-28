import AVFoundation
import Accelerate
import Combine
import Foundation

/// Manages audio metering for real-time level visualization
class AudioMeterManager: ObservableObject {
    static let shared = AudioMeterManager()

    /// Current audio level (0.0 to 1.0)
    @Published private(set) var currentLevel: Float = 0.0

    /// Whether audio is currently playing
    @Published private(set) var isPlaying: Bool = false

    /// Peak level for visual interest
    @Published private(set) var peakLevel: Float = 0.0

    private var levelUpdateTimer: Timer?
    private var peakDecayTimer: Timer?

    private let levelSmoothing: Float = 0.3  // Lower = more responsive, higher = smoother
    private let peakDecayRate: Float = 0.05
    private let updateInterval: TimeInterval = 1.0 / 30.0  // 30 FPS

    // Store recent levels for smoothing
    private var recentLevels: [Float] = []
    private let maxRecentLevels = 5

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotifications()
    }

    deinit {
        stopMetering()
        cancellables.removeAll()
    }

    // MARK: - Public API

    /// Start monitoring audio levels
    func startMetering() {
        guard levelUpdateTimer == nil else { return }

        isPlaying = true

        // Create timer for level updates
        levelUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) {
            [weak self] _ in
            self?.updateLevel()
        }

        // Create timer for peak decay
        peakDecayTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            [weak self] _ in
            self?.decayPeak()
        }
    }

    /// Stop monitoring audio levels
    func stopMetering() {
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil

        peakDecayTimer?.invalidate()
        peakDecayTimer = nil

        isPlaying = false

        // Animate back to zero
        DispatchQueue.main.async { [weak self] in
            self?.currentLevel = 0.0
        }
    }

    /// Update level from external source (e.g., audio tap)
    func updateWithRMSLevel(_ rmsLevel: Float) {
        // Convert RMS to a more visually useful range (RMS is typically quite low)
        // Typical speech RMS is around 0.01-0.1
        let scaledLevel = min(1.0, rmsLevel * 10.0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Add to recent levels for smoothing
            self.recentLevels.append(scaledLevel)
            if self.recentLevels.count > self.maxRecentLevels {
                self.recentLevels.removeFirst()
            }

            // Calculate smoothed level
            let smoothedLevel = self.recentLevels.reduce(0, +) / Float(self.recentLevels.count)

            // Apply exponential smoothing
            self.currentLevel =
                self.currentLevel * self.levelSmoothing + smoothedLevel * (1 - self.levelSmoothing)

            // Update peak
            if self.currentLevel > self.peakLevel {
                self.peakLevel = self.currentLevel
            }
        }
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted)
            .sink { [weak self] _ in
                self?.startMetering()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused)
            .sink { [weak self] _ in
                self?.stopMetering()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackTrackChanged)
            .sink { [weak self] _ in
                // Reset levels on track change
                self?.recentLevels.removeAll()
                self?.currentLevel = 0
                self?.peakLevel = 0
            }
            .store(in: &cancellables)
    }

    private func updateLevel() {
        // If we're not receiving external level updates, generate simulated levels
        // based on whether we're actually playing
        guard isPlaying else {
            currentLevel = 0
            return
        }

        // Check if we're getting real data (recent levels populated)
        if recentLevels.isEmpty {
            // Generate simulated audio-like levels for visual feedback
            // This provides a fallback when real metering isn't available
            generateSimulatedLevel()
        }
    }

    private func generateSimulatedLevel() {
        // Generate naturalistic audio levels based on typical speech patterns
        let baseLevel: Float = 0.3
        let variation: Float = Float.random(in: -0.2...0.25)

        // Occasional "peaks" like in real speech
        let peakChance = Float.random(in: 0...1)
        let peakBoost: Float = peakChance > 0.85 ? Float.random(in: 0.1...0.3) : 0

        let newLevel = max(0.1, min(1.0, baseLevel + variation + peakBoost))

        // Smooth transition
        currentLevel = currentLevel * 0.7 + newLevel * 0.3

        if currentLevel > peakLevel {
            peakLevel = currentLevel
        }
    }

    private func decayPeak() {
        if peakLevel > currentLevel {
            peakLevel = max(currentLevel, peakLevel - peakDecayRate)
        }
    }
}

// MARK: - Audio Level Calculation Helpers

extension AudioMeterManager {
    /// Calculate RMS level from an audio buffer
    static func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        guard frameLength > 0 else { return 0 }

        var totalRMS: Float = 0

        for channel in 0..<channelCount {
            let data = channelData[channel]
            var rms: Float = 0

            vDSP_rmsqv(data, 1, &rms, vDSP_Length(frameLength))
            totalRMS += rms
        }

        return totalRMS / Float(channelCount)
    }
}
