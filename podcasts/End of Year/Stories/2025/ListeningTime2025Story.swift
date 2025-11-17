import SwiftUI
import Lottie

struct ListeningTime2025Story: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let listeningTime: Double

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    let identifier: String = "total_time"

    private static let speed: Double = 0.04

    @StateObject private var stepCounter: StepCounter = .init(interval: Self.speed)
    @StateObject private var lottieTextProvider: LottieTextProvider

    init(listeningTime: Double) {
        self.listeningTime = listeningTime
        _lottieTextProvider = .init(wrappedValue: LottieTextProvider(startTime: listeningTime - (listeningTime * 0.1), endTime: listeningTime))
    }

    var formattedMinutes: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(for: Int(listeningTime / 60.0)) ?? ""
    }

    @State private var playMode: LottiePlaybackMode = .paused(at: .progress(0))

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                }
                .ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(content: {
                ZStack {
                    LottieView(animation: .named("playback2025_listening_time_numbers"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleAspectFill
                            animationView.textProvider = self.lottieTextProvider
                        })
                        .playbackMode(playMode)
                        .scaledToFill()
                        .ignoresSafeArea()
                        .zIndex(3)
                    LottieView(animation: .named("playback2025_listening_time"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleAspectFill
                        })
                        .playbackMode(playMode)
                        .scaledToFill()
                        .ignoresSafeArea()
                        .zIndex(2)
                }
            })
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .onChange(of: stepCounter.counter) { value in
            stepNumberAnimation(value)
        }
        .onAppear {
            playMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse))
        }
        .onDisappear {
            playMode = .paused(at: .progress(0))
        }
    }

    func stepNumberAnimation(_ value: Int) {
        lottieTextProvider.step()
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryListenedToShareText(formattedMinutes), year: .y2025)
        ]
    }
}

final private class LottieTextProvider: LegacyAnimationTextProvider, Equatable, ObservableObject {

    private var startTime: Double
    private var endTime: Double
    var currentTime: Double

    private static func formatted(hours: Int) -> String {
        return hours == 1 ? L10n.hoursSingularFormat : L10n.hoursPluralFormat(hours)
    }

    init(
        startTime: Double,
        endTime: Double
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.currentTime = startTime
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        if keypathName == "minutes listened" {
            return L10n.playback2025ListeningTime
        } else {
            return formattedMinutes
        }
    }

    func step() {
        if currentTime < endTime {
            currentTime += endTime * 0.01 / 4
        }
    }

    var formattedMinutes: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(for: Int(Double(currentTime) / 60.0)) ?? ""
    }

    static func == (lhs: LottieTextProvider, rhs: LottieTextProvider) -> Bool {
        return lhs.startTime == rhs.startTime && lhs.endTime == lhs.endTime
    }
}

struct GrowingParallelShape: Shape {
    var growFactor: CGFloat

    var animatableData: CGFloat {
        get { growFactor }
        set { growFactor = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let centerY = rect.midY

        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: centerY + (rect.height * 0.78 * growFactor)))
        path.addLine(to: CGPoint(x: rect.maxX, y: centerY + (rect.height * 0.6 / 2 * growFactor)))
        path.addLine(to: CGPoint(x: rect.maxX, y: centerY - (rect.height * 0.9 / 2 * growFactor)))
        path.addLine(to: CGPoint(x: rect.minX, y: centerY - (rect.height * 1 * growFactor)))

        path.closeSubpath()
        return path
    }
}

#Preview("Days") {
    ListeningTime2025Story(listeningTime: 4.day + 5.hour + 20.minutes)
}

#Preview("Days hour min") {
    ListeningTime2025Story(listeningTime: 1.day + 5.hour + 20.minutes)
}

#Preview("Day and min") {
    ListeningTime2025Story(listeningTime: 1.day + 20.minutes)
}

#Preview("Hours") {
    ListeningTime2025Story(listeningTime: 5.hours + 20.minutes)
}

#Preview("Minutes") {
    ListeningTime2025Story(listeningTime: 60)
}

#Preview("Seconds") {
    ListeningTime2025Story(listeningTime: 30)
}

#Preview("Zero") {
    ListeningTime2025Story(listeningTime: 0)
}
