import SwiftUI
import Lottie
import PocketCastsServer

extension Color {
    static let endOfYear2025Background = Color(hex: "28486A")
}

struct IntroStory2025: StoryView {
    let identifier: String = "cover"

    let backgroundColor = Color.endOfYear2025Background
    let backgroundTextColor = Color.white

    @State private var opacity = CGFloat(0)
    @State private var scale = CGFloat(0.5)
    @State private var animationProgress: AnimationProgressTime = .zero

    @State private var openCircle: Bool = false
    @State private var animationFinished = false
    @EnvironmentObject var syncProgressModel: SyncYearListeningProgress

    private let afterLoading: Bool

    let loadCallback: (() -> ())?

    init(afterLoading: Bool, loadCallback: (() -> ())? = nil) {
        self.loadCallback = loadCallback
        self.afterLoading = afterLoading
    }

    enum KeyFrames {
        static var circleOpen = CGFloat(110)
    }

    var body: some View {
        ZStack {
            Text(L10n.playback2025IntroMessage)
                .multilineTextAlignment(.center)
                .font(size: 25, style: .title, weight: .semibold)
                .foregroundStyle(backgroundTextColor)
                .mask(
                    Circle().scale(scale)
                )
                .opacity(animationFinished ? 0 : opacity)
        }
        .onChange(of: animationProgress) { position in
            if afterLoading {
                self.opacity = 1
                self.scale = 10
            } else {
                if position > KeyFrames.circleOpen, !openCircle {
                    openCircle = true
                    withAnimation(.easeInOut(duration: 0.005)) {
                        self.opacity = 1
                    }
                    withAnimation(.easeInOut(duration: 1)) {
                        self.scale = 10
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                if animationFinished {
                    VStack(spacing: 15) {
                        Spacer()
                        CircularProgressView(value: syncProgressModel.progress, stroke: .white, strokeWidth: 6)
                            .frame(width: 40, height: 40)
                        Spacer()
                    }
                } else {
                    LottieView(animation: .named("end_of_year_2025_intro"))
                        .animationDidFinish({ completed in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                animationFinished = true
                                loadCallback?()
                            }
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleAspectFill
                        })
                        .playbackMode(afterLoading ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                        .getRealtimeAnimationFrame($animationProgress)
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
        )
        .ignoresSafeArea()
        .background(backgroundColor)
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }
}

struct IntroStory2025_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory2025(afterLoading: false)
    }
}
