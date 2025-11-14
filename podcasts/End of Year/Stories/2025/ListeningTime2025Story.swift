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

    @State var growFactor: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    VStack(alignment: .leading) {
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
                                .kerning(0.52)
                            Spacer()
                        }
                    }
                    .border(.green)
                    .padding(.horizontal, 30)                    
                    .border(.red)
                    .clipShape(GrowingParallelShape(growFactor: growFactor))
                }
                .padding(.bottom, geometry.size.height * 0.23)
                .border(.orange)
                .ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(content: {
                LottieView(animation: .named("playback2025_listening_time"))
                    .animationDidFinish({ completed in
                    })
                    .configure({ animationView in
                    })
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                    .ignoresSafeArea()
                    .scaleEffect(x: 1.2, y: 1)
            })
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .onChange(of: stepCounter.counter) { value in
            stepNumberAnimation(value)
        }
        .onAppear() {
            withAnimation(.timingCurve(0.33, 0, 0, 1, duration: 1.5)) {
                growFactor = 1
            }
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

struct GrowingCenteredRect: Shape {
    var currentHeight: CGFloat

    var animatableData: CGFloat {
        get { currentHeight }
        set { currentHeight = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let halfHeight = min(currentHeight / 2, rect.height / 2)
        let centerY = rect.midY
        let top = centerY - halfHeight
        let bottom = centerY + halfHeight

        return Path(CGRect(x: rect.minX, y: top, width: rect.width, height: bottom - top))
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
