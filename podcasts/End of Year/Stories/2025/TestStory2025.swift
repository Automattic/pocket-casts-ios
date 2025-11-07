import SwiftUI
import Lottie

struct TestStory2025: ShareableStory {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background
    let identifier: String = "test_animation"

    let listeningTime: Double
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    var formattedMinutes: String {
        return formatter.string(for: Int(currentTime / 60.0)) ?? ""
    }

    @State private var currentTime: Double
    @State var playAnimation = false

    init(listeningTime: Double) {
        self.listeningTime = listeningTime
        _currentTime = .init(initialValue: listeningTime - (listeningTime * 0.1))
    }

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
            ZStack {
                LottieView(animation: .named("05-background-only_i1"))
                    .configure({ animationView in
                        animationView.contentMode = .scaleToFill
                    })
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                LottieView(animation: .named("05-numbers-only_i1"))
                    .configure({ animationView in
                        animationView.contentMode = .scaleToFill
                        animationView.textProvider = MyLottieTextProvider2(text: formattedMinutes)
                        animationView.fontProvider = MyFontProvider()
                    })
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
//                LottieView(animation: .named("05_(with hidden text)_i4"))
//                    .configure({ animationView in
//                        animationView.contentMode = .scaleToFill
//                        animationView.textProvider = MyLottieTextProvider2(text: formattedMinutes)
//                        animationView.fontProvider = MyFontProvider()
//                        animationView.forceDisplayUpdate()
//                    })
//                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
            }
            .scaledToFill()
        })
        .ignoresSafeArea()
        .background(backgroundColor)
        .onAppear {
            animateToListeningTime()
        }
    }

    func animateToListeningTime() {
        let duration: Double = 1.9
        let steps: Int = 60 // smooth enough (≈60 FPS)
        let interval = duration / Double(steps)
        let increment = (listeningTime - currentTime) / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.linear(duration: interval)) {
                    self.currentTime = min(self.currentTime + increment, listeningTime)
                }
            }
        }
    }

    @ViewBuilder var headerView: some View {
        StoryHeader2025(title: "Test Animation")
    }
}

final class MyLottieTextProvider2: AnimationTextProvider, Equatable {
    let s: String

    init(text: String) {
        self.s = text
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        if keypathName == "40,456" { //content.40,456
//        if keypathName == "content.40,456" { //
            print("AAAA Text \(keypathName), \(s)")
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
        switch family {
        case "Inter-Medium", "Inter-Regular":
            let font = UIFont(name: "Inter-Regular_Medium", size: size)!
            return CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        default:
            let font = UIFont(name: "Humane-SemiBold", size: size)!
            return CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        }
    }
}

#Preview() {
    TestStory2025(listeningTime: 4.day + 5.hour + 20.minutes)
}

/*
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
 */
