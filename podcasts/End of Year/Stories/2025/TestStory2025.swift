import SwiftUI
import Lottie

struct TestStory2025: ShareableStory {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "test_animation"
    
    @State private var currentText: String = "0"
    
    @State private var animationProgress: AnimationProgressTime = .zero
    @State private var animationViewRef: LottieAnimationView?

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
//                    animationViewRef = animationView
                    animationView.contentMode = .scaleToFill
                    animationView.logHierarchyKeypaths()
//                    animationView.textProvider = MyLottieTextProvider2(text: currentText)
//                    let colorKeypath = AnimationKeypath(keypath: "main number.Animator 1.Fill Color")
//                    let colorProvider = ColorValueProvider(LottieColor(r: 1, g: 1, b: 1, a: 1))
//                    animationView.setValueProvider(colorProvider, keypath: colorKeypath)

//                    animationView.textProvider = MyLottieTextProvider()
//                    let colorKeypath = AnimationKeypath(keypath: "2025.Animator 1.Fill Color")
//                    let colorKeypath2 = AnimationKeypath(keypath: "150 hours.Animator 1.Fill Color")
//                    let colorProvider = ColorValueProvider(LottieColor(r: 0, g: 1, b: 1, a: 1))
//                    animationView.setValueProvider(colorProvider, keypath: colorKeypath)
//                    let colorProvider2 = ColorValueProvider(LottieColor(r: 1, g: 1, b: 0, a: 1))
//                    animationView.setValueProvider(colorProvider2, keypath: colorKeypath2)

                    animationView.fontProvider = MyFontProvider()
                })
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
//                .getRealtimeAnimationFrame($animationProgress)
//                .playbackMode(.playing(.marker("marker_9", loopMode: .playOnce)))
//                .playbackMode(.paused)
                .scaledToFill()
//                .scaleEffect(0.5)
                .ignoresSafeArea()
        }
        )
        .ignoresSafeArea()
        .background(backgroundColor)
//        .onChange(of: currentText) { newValue in
//            animationViewRef?.textProvider = MyLottieTextProvider2(text: newValue)
//        }
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
        let view = LottieView(animation: .named("test_animation_05"))
//        let view = LottieView(animation: .named("test_animation_3"))
//        let view = LottieView(animation: .named("test_animation_2"))
//        return view.textProvider(MyLottieTextProvider2(text: currentText))
        return view
    }
}

final class MyLottieTextProvider: AnimationTextProvider, Equatable {
    private let dict: [String: String]

    init() {
        dict = [
            "2024": "2000",
            "150 hours": "300 ore",
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
        print("AAAA \(keypathName), \(sourceText)")
        return s
    }

    static func == (lhs: MyLottieTextProvider2, rhs: MyLottieTextProvider2) -> Bool {
        lhs.s == rhs.s
    }
}

class MyFontProvider: AnimationFontProvider {
    func fontFor(family: String, size: CGFloat) -> CTFont? {
        print("AAAA font \(family)")
        switch family {
        case "Inter-Medium":
            return CTFontCreateWithName("Humane-Medium" as CFString, size, nil)
        default:
            return CTFontCreateWithName("Humane-Medium" as CFString, 80, nil)
        }
    }
}
