import SwiftUI
import Combine

/// An animated audio waveform visualization for the player that reacts to audio levels
struct PlayerAudioWaveformView: View {
    @ObservedObject var audioMeter: AudioMeterManager

    let barCount: Int
    let barWidth: CGFloat
    let barSpacing: CGFloat
    let primaryColor: Color
    let secondaryColor: Color

    @State private var barHeights: [CGFloat]
    @State private var targetHeights: [CGFloat]

    private let minHeightFraction: CGFloat = 0.1
    private let maxHeightFraction: CGFloat = 0.8
    private let animationDuration: Double = 0.08

    init(
        audioMeter: AudioMeterManager,
        barCount: Int = 40,
        barWidth: CGFloat = 4,
        barSpacing: CGFloat = 4,
        primaryColor: Color = .white,
        secondaryColor: Color = .gray.opacity(0.5)
    ) {
        self.audioMeter = audioMeter
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor

        // Initialize bar heights with a wave pattern
        let initialHeights = (0..<barCount).map { index -> CGFloat in
            let basePattern = Self.calculateBaseHeight(for: index, total: barCount)
            return basePattern
        }
        _barHeights = State(initialValue: initialHeights)
        _targetHeights = State(initialValue: initialHeights)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        height: barHeights[safe: index] ?? minHeightFraction,
                        maxHeight: geometry.size.height,
                        width: barWidth,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        index: index,
                        total: barCount
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onChange(of: audioMeter.currentLevel) { newLevel in
            updateBarsForLevel(newLevel)
        }
        .onChange(of: audioMeter.isPlaying) { isPlaying in
            if !isPlaying {
                resetBarsToIdle()
            }
        }
        .onAppear {
            if audioMeter.isPlaying {
                updateBarsForLevel(audioMeter.currentLevel)
            }
        }
    }

    private func updateBarsForLevel(_ level: Float) {
        // Normalize level (typically comes in as 0.0 to 1.0, but can vary)
        let normalizedLevel = CGFloat(min(max(level, 0), 1))

        // Generate new target heights based on audio level
        var newHeights = [CGFloat]()

        for index in 0..<barCount {
            let baseHeight = Self.calculateBaseHeight(for: index, total: barCount)

            // Add variation based on audio level
            let levelInfluence = normalizedLevel * (maxHeightFraction - minHeightFraction)

            // Add some randomness for natural look, influenced by current level
            let randomFactor = CGFloat.random(in: -0.1...0.1) * normalizedLevel

            // Calculate final height - center bars react more
            let centerDistance = abs(CGFloat(index) - CGFloat(barCount) / 2) / CGFloat(barCount / 2)
            let centerBoost = (1 - centerDistance) * 0.3 * normalizedLevel

            let finalHeight = min(maxHeightFraction, baseHeight + levelInfluence + randomFactor + centerBoost)
            newHeights.append(max(minHeightFraction, finalHeight))
        }

        withAnimation(.easeOut(duration: animationDuration)) {
            barHeights = newHeights
        }
    }

    private func resetBarsToIdle() {
        let idleHeights = (0..<barCount).map { index -> CGFloat in
            Self.calculateBaseHeight(for: index, total: barCount)
        }

        withAnimation(.easeOut(duration: 0.3)) {
            barHeights = idleHeights
        }
    }

    /// Calculate a base height pattern that looks like a waveform even when idle
    private static func calculateBaseHeight(for index: Int, total: Int) -> CGFloat {
        // Create a gentle wave pattern centered in the middle
        let center = CGFloat(total) / 2
        let distance = abs(CGFloat(index) - center) / center

        // Base pattern: taller in center, shorter at edges
        let baseHeight: CGFloat = 0.15 + (1 - distance) * 0.15

        // Add subtle variation every few bars
        let variation: CGFloat
        switch index % 5 {
        case 0: variation = 0.05
        case 2: variation = -0.03
        default: variation = 0
        }

        return max(0.1, baseHeight + variation)
    }
}

/// Individual bar in the waveform
private struct WaveformBar: View {
    let height: CGFloat  // Fraction of max height (0.0 to 1.0)
    let maxHeight: CGFloat
    let width: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    let index: Int
    let total: Int

    var body: some View {
        let actualHeight = maxHeight * height

        RoundedRectangle(cornerRadius: width / 2)
            .fill(barGradient)
            .frame(width: width, height: actualHeight)
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryColor, secondaryColor]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Preview
#if DEBUG
struct PlayerAudioWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            PlayerAudioWaveformView(
                audioMeter: AudioMeterManager.shared,
                primaryColor: .white,
                secondaryColor: .gray.opacity(0.5)
            )
            .frame(width: 300, height: 200)
        }
    }
}
#endif
