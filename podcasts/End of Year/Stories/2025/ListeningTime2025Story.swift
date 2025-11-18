import SwiftUI
import Lottie

struct ListeningTime2025Story: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let listeningTime: Double

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    let identifier: String = "total_time"

    private static let speed: Double = 0.05

    @StateObject private var stepCounter: StepCounter = .init(interval: Self.speed)
    private var lottieTextProvider: LottieTextProvider

    init(listeningTime: Double) {
        self.listeningTime = listeningTime
        lottieTextProvider = LottieTextProvider(startTime: listeningTime - (listeningTime * 0.1), endTime: listeningTime)
    }

    var formattedMinutes: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(for: Int(listeningTime / 60.0)) ?? ""
    }

    @State private var playMode: LottiePlaybackMode = .paused(at: .progress(0))
    @State private var playModeNumbers: LottiePlaybackMode = .paused(at: .progress(0))

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
                        .playbackMode(playModeNumbers)
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
        .onAppear {
            playMode = renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
            playModeNumbers = renderForSharing ? .playing(.fromProgress(0.5, toProgress: 1, loopMode: .playOnce)) : .playing(.fromProgress(0.015, toProgress: 1, loopMode: .playOnce))
            stepCounter.start()
        }
        .onDisappear {
            playMode = .paused(at: .progress(0))
        }
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

final private class LottieTextProvider: AnimationKeypathTextProvider {

    private var startTime: Double
    private var endTime: Double
    var currentTime: Double
    private var formatter: NumberFormatter

    init(
        startTime: Double,
        endTime: Double
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.currentTime = startTime
        self.formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
    }

    func text(for keypath: Lottie.AnimationKeypath, sourceText: String) -> String? {
        if keypath.string == "minutes listened" {
            return L10n.playback2025ListeningTime
        } else {
            step()
            return formattedMinutes
        }
    }

    func step() {
        if currentTime < endTime {
            currentTime += endTime * 0.01 / 4
        }
    }

    var formattedMinutes: String {
        return formatter.string(for: Int(currentTime / 60.0)) ?? ""
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
