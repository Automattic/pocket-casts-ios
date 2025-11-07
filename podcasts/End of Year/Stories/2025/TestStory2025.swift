import SwiftUI
import Lottie

struct TestStory2025: ShareableStory {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "test_animation"
    
    @State private var currentText: String = "0"

    @State private var animationProgress: AnimationProgressTime = .zero

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
//                    animationView.textProvider = MyLottieTextProvider2(text: formattedMinutes)
//                    let colorKeypath = AnimationKeypath(keypath: "main number.Animator 1.Fill Color")
//                    let colorProvider = ColorValueProvider(LottieColor(r: 1, g: 1, b: 1, a: 1))
//                    animationView.setValueProvider(colorProvider, keypath: colorKeypath)

                    animationView.textProvider = MyLottieTextProvider()
//                    let colorKeypath = AnimationKeypath(keypath: "2025.Animator 1.Fill Color")
//                    let colorKeypath2 = AnimationKeypath(keypath: "150 hours.Animator 1.Fill Color")
//                    let colorProvider = ColorValueProvider(LottieColor(r: 0, g: 1, b: 1, a: 1))
//                    animationView.setValueProvider(colorProvider, keypath: colorKeypath)
//                    let colorProvider2 = ColorValueProvider(LottieColor(r: 1, g: 1, b: 0, a: 1))
//                    animationView.setValueProvider(colorProvider2, keypath: colorKeypath2)

                    animationView.fontProvider = MyFontProvider()
                })
//                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
//                .getRealtimeAnimationFrame($animationProgress)
                .playbackMode(.playing(.marker("marker_4", loopMode: .playOnce)))
//                .playbackMode(.playing(.fromFrame(675, toFrame: (675+150), loopMode: .playOnce)))
//                .playbackMode(.paused)
                .scaledToFill()
                .scaleEffect(0.5)
                .ignoresSafeArea()
        }
        )
        .ignoresSafeArea()
        .background(backgroundColor)
//        .enableProportionalValueScaling()
//        .onChange(of: stepCounter.counter) { value in
//                    stepNumberAnimation(value)
//                }
//        .onAppear {
//            for i in 0..<100 {
//                DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.01) {
//                    currentText = "\(i)"
//                    stepNumberAnimation(i)
//                }
//            }
//        }
    }
    
    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: "Test Animation")
    }

    var customView: LottieView<EmptyView> {
        let view = LottieView(animation: .named("04_stats_i16"))
//        let view = LottieView(animation: .named("test_animation_3"))
//        let view = LottieView(animation: .named("test_animation"))
//        return view.textProvider(MyLottieTextProvider2(text: currentText))
        return view
    }
}

final class MyLottieTextProvider: AnimationTextProvider, Equatable {
    private let dict: [String: String]

    init() {
        dict = [
//            "2024": "2000",
//            "150 hours": "300 ore",
//            "2024": "2000",
            "main number": "5",
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
        print("AAAA Text \(keypathName), \(sourceText)")
        if keypathName == "content.MAIN NUMBER.40,456" {
            return s
        }
        return "minutes listened"
    }

    static func == (lhs: MyLottieTextProvider2, rhs: MyLottieTextProvider2) -> Bool {
        lhs.s == rhs.s
    }
}

class MyFontProvider: AnimationFontProvider {
    func fontFor(family: String, size: CGFloat) -> CTFont? {
        print("AAAA font \(family)")
        switch family {
        case "Inter-Medium", "Inter-Regular":
            let font = UIFont(name: "Inter-Regular", size: 32)!
            return CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        default:
            let font = UIFont(name: "Humane-SemiBold", size: 300)!
            return CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        }
    }
}
