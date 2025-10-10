import SwiftUI
import Lottie

extension Color {
    static let endOfYear2025Background = Color(hex: "28486A")
}

struct IntroStory2025: StoryView {
    let identifier: String = "cover"

    let backgroundColor = Color.endOfYear2025Background
    let backgroundTextColor = Color.white

    @State private var opacity = CGFloat(0)
    @State private var scale = CGFloat(0.5)

    var body: some View {
        ZStack {
            Text(L10n.playback2025IntroMessage)
                .multilineTextAlignment(.center)
                .font(size: 25, style: .title, weight: .semibold)
                .foregroundStyle(backgroundTextColor)
                .mask(
                    Circle().scale(scale)
                )
                .opacity(opacity)
        }
        .onAppear() {
            withAnimation(.easeInOut(duration: 0.005).delay(3.85)) {
                self.opacity = 1
            }
            withAnimation(.easeInOut(duration: 0.3).delay(3.9)) {
                self.scale = 9
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LottieView(animation: .named("end_of_year_2025_intro"))
                .animationDidFinish({ completed in
                })
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFill
                })
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                .scaledToFill()
                .ignoresSafeArea()
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
        IntroStory2025()
    }
}
