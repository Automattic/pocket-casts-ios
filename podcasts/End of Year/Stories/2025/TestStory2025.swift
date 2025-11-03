import SwiftUI
import Lottie

struct TestStory2025: ShareableStory {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "test_animation"
    
    @State private var currentText: String = "0"

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
        .onAppear {
            for i in 0..<100 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                    currentText = "\(i)"
                }
            }
        }
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: "Test Animation")
    }

    var customView: LottieView<EmptyView> {
        let view = LottieView(animation: .named("test_animation"))
        return view.textProvider(MyLottieTextProvider2(text: currentText))
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

final class MyLottieTextProvider2: AnimationTextProvider, Equatable {
    let s: String
    
    init(text: String) {
        self.s = text
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        return s
    }

    static func == (lhs: MyLottieTextProvider2, rhs: MyLottieTextProvider2) -> Bool {
        lhs.s == rhs.s
    }
}
