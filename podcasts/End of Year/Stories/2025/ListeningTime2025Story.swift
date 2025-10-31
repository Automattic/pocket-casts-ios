import SwiftUI
import Lottie

struct ListeningTime2025Story: ShareableStory {

    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let listeningTime: Double

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    let identifier: String = "total_time"

    private let startTime: Double
    private let endTime: Double

    private static let speed: Double = 0.01

    @StateObject private var stepCounter: StepCounter = .init(interval: Self.speed)
    @State private var currentTime: Double

    init(listeningTime: Double) {
        self.listeningTime = listeningTime
        startTime = listeningTime - (listeningTime * 0.1)
        endTime = listeningTime
        _currentTime = .init(initialValue: startTime)
    }

    var formattedMinutes: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(for: Int(currentTime / 60.0)) ?? ""
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    let sizingFactor = 0.25
                    let font = UIFont(name: "Humane-SemiBold", size: geometry.size.height * sizingFactor) ?? UIFont.systemFont(ofSize: geometry.size.height * sizingFactor)
                    Text(formattedMinutes)
                        .lineLimit(1)
                        .font(Font(font as CTFont))
                        .minimumScaleFactor(0.5)
                    HStack {
                        Text(L10n.playback2025ListeningTime)
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .kerning(0.54)
                        Spacer()
                    }
                }
                .padding(.bottom, geometry.size.height * 0.17)
                .padding(.horizontal, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(content: {
                if renderForSharing {
                    Image("playback_2025_listening_time_back")
                        .resizable()
                        .scaledToFit()
                } else {
                    LottieView(animation: .named("playback2025_listening_time"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleToFill
                        })
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            })
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .enableProportionalValueScaling()
        .onChange(of: stepCounter.counter) { value in
            stepNumberAnimation(value)
        }
    }

    func stepNumberAnimation(_ value: Int) {
        if currentTime < endTime {
            withAnimation(.easeIn(duration: Self.speed)) {
                currentTime = listeningTime * 0.01 * Double(value)
            }
        } else {
            currentTime = endTime
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
