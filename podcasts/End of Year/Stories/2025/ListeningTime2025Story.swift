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
                if renderForSharing {
                    Image("playback_2025_listening_time_back")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LottieView(animation: .named("playback2025_listening_time"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleAspectFill
                        })
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
//                        .scaledToFill()
                        .ignoresSafeArea()
                }
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
                .background(Color.red.opacity(0.5))
                .ignoresSafeArea()
                .mask(alignment: .topLeading, {
                    LottieView(animation: .named("test_05_mask_02"))
                        .configure({ animationView in
                            animationView.contentMode = .scaleAspectFill
                        })
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
//                        .frame(width: geometry.size.width, height: geometry.size.height)
//                        .scaledToFill()
                        .ignoresSafeArea()
//                        .scaleEffect(0.5)
//                        .position(CGPoint(x: geometry.frame(in: .global).minX, y: geometry.frame(in: .global).minY))
//                        .frame(width: geometry.frame(in: .global).width, height: geometry.frame(in: .global).height)
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(content: {
//
//            })
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
//        .enableProportionalValueScaling()
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

struct TestView: View {
    @State private var animatedHeight: CGFloat = 0

    var body: some View {
        ZStack {
            MaskedView()
//                .mask(alignment: .center, {
//                    LottieView(animation: .named("test_05_mask_02"))
//                        .resizable()
//                        .configure({ animationView in
//                            animationView.contentMode = .topLeft
//                        })
//                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
//                        .ignoresSafeArea()
//                        .opacity(0.5)
//                })
//                .clipShape(GrowingRectFixedHeight(currentHeight: animatedHeight))
//                                .animation(.easeOut(duration: 1), value: animatedHeight)

        }
        .background(Color.red)
        .onAppear {
//            animatedHeight = 100
        }
    }
}

struct GrowingRectFixedHeight: Shape {
    var currentHeight: CGFloat

    var animatableData: CGFloat {
        get { currentHeight }
        set { currentHeight = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let height = min(currentHeight, rect.height)
        let yOffset = rect.maxY - height
        return Path(CGRect(x: rect.minX, y: yOffset, width: rect.width, height: height))
    }
}

struct MaskedView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                NumbersView(size: geometry.size)
                    .padding(.bottom, geometry.size.height * 0.235)
                    .padding(.horizontal, 30)
            }
            .background {
                LottieView(animation: .named("playback2025_listening_time"))
                    .animationDidFinish({ completed in
                    })
                    .configure({ animationView in
                        animationView.contentMode = .scaleAspectFill
                    })
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                    .ignoresSafeArea()
            }
        }
    }
}

struct NumbersView: View {
    let size: CGSize

    @State private var clipHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let sizingFactor = 0.25
            let font = UIFont(name: "Humane-SemiBold", size: size.height * sizingFactor) ?? UIFont.systemFont(ofSize: size.height * sizingFactor)
            Text("20,450")
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
        .clipShape(GrowingCenteredRect(currentHeight: clipHeight))
        .animation(.easeOut(duration: 4), value: clipHeight)
        .onAppear {
            clipHeight = 200
        }
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

#Preview("Numbers") {
    NumbersView(size: CGSize(width: 640, height: 1080))
}

#Preview("Masked") {
    TestView()
}

//#Preview("Days") {
//    ListeningTime2025Story(listeningTime: 4.day + 5.hour + 20.minutes)
//}
//
//#Preview("Days hour min") {
//    ListeningTime2025Story(listeningTime: 1.day + 5.hour + 20.minutes)
//}
//
//#Preview("Day and min") {
//    ListeningTime2025Story(listeningTime: 1.day + 20.minutes)
//}
//
//#Preview("Hours") {
//    ListeningTime2025Story(listeningTime: 5.hours + 20.minutes)
//}
//
//#Preview("Minutes") {
//    ListeningTime2025Story(listeningTime: 60)
//}
//
//#Preview("Seconds") {
//    ListeningTime2025Story(listeningTime: 30)
//}
//
//#Preview("Zero") {
//    ListeningTime2025Story(listeningTime: 0)
//}
