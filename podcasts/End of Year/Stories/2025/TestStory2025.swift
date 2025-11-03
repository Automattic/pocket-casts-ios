import SwiftUI
import Lottie

struct TestStory2025: ShareableStory {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "test_animation"

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                headerView
                Spacer()
            }
            .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(content: {
                customView
                .animationDidFinish({ completed in
                })
                .configure({ animationView in
                    animationView.contentMode = .scaleToFill
                })
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                .scaledToFill()
                .scaleEffect(0.5)
                .ignoresSafeArea()
        }
        )
        .ignoresSafeArea()
        .background(backgroundColor)
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: "Test Animation")
    }

    var customView: LottieView<EmptyView> {
        let view = LottieView(animation: .named("test_animation"))
        return view.textProvider(MyLottieTextProvider())
    }
}

final class MyLottieTextProvider: AnimationTextProvider, Equatable {
    private let dict: [String: String]

    init() {
        dict = [
            "1": "100",
        ]
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        print("AAAA \(keypathName), \(sourceText)")
        return dict[keypathName] ?? sourceText
    }
    
    static func == (lhs: MyLottieTextProvider, rhs: MyLottieTextProvider) -> Bool {
        lhs.dict == rhs.dict
    }
}
