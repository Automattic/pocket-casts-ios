import SwiftUI

struct PatronUnlockButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var unlockHaptic = UnlockHaptic(duration: Constants.duration)
    @State private var state: UnlockState = .waiting
    @State private var startDate: Date? = nil

    var onFinished: (() -> Void)? = nil
    var onProgress: ((Double) -> Void)? = nil

    private var progress: Double {
        startDate.map { Date.now.timeIntervalSince($0) / Constants.duration } ?? 0
    }

    private var label: String {
        switch progress {
        case 1...:
            return L10n.patronUnlockRelease
        case 0.01...:
            return L10n.patronUnlocking
        default:
            return L10n.patronUnlockWord.localizedCapitalized
        }
    }

    var body: some View {
        if reduceMotion {
            Button(label) {
                finish()
            }
            .buttonStyle(HapticProgressButtonStyle(progress: 1))
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: state != .progress)) { _ in
                // Ignore the button action
                Button(label) {}
                    .buttonStyle(HapticProgressButtonStyle(progress: progress))
                // A long press gesture on a button doesn't trigger the long press action
                    .onLongPressGesture(minimumDuration: 0) {} onPressingChanged: { pressed in
                        // If we're not pressing, then start things up ahead
                        guard pressed == false else {
                            start()
                            unlockHaptic.play()
                            return
                        }

                        // Stop the haptics no matter what
                        unlockHaptic.stop()

                        // Check for completion, if not reset everything
                        guard progress >= 1.0 else {
                            reset()
                            return
                        }

                        finish()

                    }
                    // Use an overlay with an Action to send the progress whenever the view redraws
                    // This provides a smoother effect than onChange and SwiftUI doesn't complain about sending
                    // too many updates
                    .overlay(
                        Action {
                            if state == .progress {
                                onProgress?(progress.clamped(to: 0..<1))
                            }
                        }
                    )
            }
        }
    }

    private func start() {
        state = .progress
        startDate = .now
    }

    private func reset() {
        state = .waiting
        startDate = nil
        onProgress?(0)
    }

    private func finish() {
        state = .done
        startDate = nil

        onFinished?()
    }

    private enum UnlockState {
        case waiting, progress, done
    }

    private enum Constants {
        static let duration: TimeInterval = 1.5
    }
}

// MARK: - Button Style
private struct HapticProgressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var progress: Double = 0

    private var scale: Double {
        let max = progress > 0.5 ? 1.03 : 1.01
        return Double.random(in: 1.0..<max)
    }

    private var rotation: Double {
        reduceMotion ? 0 : progress > 0.5 ? Double(Int.random(in: -1..<2)) : 0
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)

            .background(
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color.patronBackgroundColor
                            .opacity(0.75)
                        Color.patronBackgroundColor
                            .frame(width: proxy.size.width * progress, alignment: .trailing)
                    }
                }
            )

            .foregroundColor(Color.patronButtonFilledTextColor)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .contentShape(Rectangle())
            .shadow(color: .black.opacity(0.7 * progress), radius: Double.random(in: 5..<10))
            .shadow(color: .white.opacity(0.7 * progress), radius: Double.random(in: 5..<10))
            // Rumble Effect that becomes more intense
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
    }
}

struct HapticProgressButton_Previews: PreviewProvider {
    static var previews: some View {
        PatronUnlockButton()
            .padding()
    }
}
