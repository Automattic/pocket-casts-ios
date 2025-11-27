import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import Lottie

struct YearOverYearCompare2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let subscriptionTier: SubscriptionTier
    let listeningTime: YearOverYearListeningTime

    let plusOnly = true
    let identifier: String = "year_over_year"

    private let foregroundColor = Color.white
    private let backgroundColor = Color(hex: "#A22828")

    var body: some View {
        VStack(alignment: .center) {
            headerView
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LottieView(animation: .named(animationName))
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFill
                    animationView.textProvider = LottieTextProvider(prevYear: listeningTime.totalPlayedTimeLastYear, currentYear: listeningTime.totalPlayedTimeThisYear)
                    animationView.fontProvider = MyFontProvider()
                })
                .playbackMode(renderForSharing ? .paused(at: .progress(1)) : .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                .scaledToFill()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
    }

    @ViewBuilder var headerView: some View {
        let content = headerContent
        StoryHeader2025(
            title: content.title,
            description: content.description,
            subscriptionTier: subscriptionTier
        )
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            // TODO: This part, images and text, need to be updated
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearOverShareText("2025", "2024"), year: .y2025)
        ]
    }

    enum Comparison {
        case down(Double)
        case up(Double)
        case same

        init(in2024: Double, in2025: Double) {
            guard in2024 != 0 else {
                // Any missing 2024 values will be treated as >500% increase
                self = .up(Double.greatestFiniteMagnitude)
                return
            }

            let difference = in2025/in2024
            // If the difference between them is < 10% in either direction, return .same:
           if abs(1 - difference) <= 0.1 {
                self = .same
            } else if difference > 1 {
                self = .up(difference - 1.0)
            } else {
                self = .down(1.0 - difference)
            }
        }
    }

    struct HeaderContent {
        let title: String
        let description: String
    }

    private var comparison: Comparison {
        .init(in2024: listeningTime.totalPlayedTimeLastYear, in2025: listeningTime.totalPlayedTimeThisYear)
    }

    var isSame: Bool {
        switch comparison {
        case .same:
            true
        default:
            false
        }
    }

    private func fontSizes() -> (Double, Double) {
        let big: Double = 128
        let small: Double = 108
        switch comparison {
        case .down:
            return (big, small)
        case .up:
            return (small, big)
        case .same:
            return (small, big)
        }
    }

    private var headerContent: HeaderContent {
        let maximumDifference: Double = 5
        let formatStyle = FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0))
        let title: String
        let description: String
        switch comparison {
        case .down(let difference):
            let formatted = min(difference, maximumDifference).formatted(formatStyle)
            title = L10n.playback2025YearOverYearComparisonDownTitle(formatted)
            description = L10n.playback2025YearOverYearComparisonDownMessage
        case .up(let difference):
            let formatted = min(difference, maximumDifference).formatted(formatStyle)
            if difference > maximumDifference {
                title = L10n.playback2025YearOverYearComparisonHeroTitle
                description = L10n.playback2025YearOverYearComparisonHeroMessage(formatted)
            } else {
                title = L10n.playback2025YearOverYearComparisonUpTitle(formatted)
                description = L10n.playback2025YearOverYearComparisonUpMessage
            }
        case .same:
            title = L10n.playback2025YearOverYearComparisonSameTitle
            description = L10n.playback2025YearOverYearComparisonSameMessage
        }
        return HeaderContent(title: title, description: description)
    }

    private var animationName: String {
        let maximumDifference: Double = 5
        switch comparison {
        case .down:
            return "2025_yoy_down"
        case .up(let difference):
            if difference > maximumDifference {
                return "2025_yoy_up_max"
            } else {
                return "2025_yoy_up"
            }
        case .same:
            return "2025_yoy_same"
        }
    }
}

final private class LottieTextProvider: LegacyAnimationTextProvider, Equatable {
    private let dict: [String: String]
    private let prevYear: Int
    private let currentYear: Int

    private static func formatted(hours: Int) -> String {
        return hours == 1 ? L10n.hoursSingularFormat : L10n.hoursPluralFormat(hours)
    }

    init(
        prevYear: Double,
        currentYear: Double
    ) {
        self.prevYear = Int(prevYear/3600)
        self.currentYear = Int(currentYear/3600)
        dict = [
            "hours_2024": Self.formatted(hours: self.prevYear),
            "hours_2025": Self.formatted(hours: self.currentYear)
        ]
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        return dict[keypathName] ?? sourceText
    }

    static func == (lhs: LottieTextProvider, rhs: LottieTextProvider) -> Bool {
        lhs.dict == rhs.dict
    }
}

fileprivate class MyFontProvider: AnimationFontProvider {
    func fontFor(family: String, size: CGFloat) -> CTFont? {
        let font = UIFont(name: family, size: size)!
        return CTFontCreateWithName("Inter-Regular_Semibold" as CFString, font.pointSize, nil)
    }
}

#Preview("Down") {
    YearOverYearCompare2025Story(subscriptionTier: .plus, listeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 968*60*60, totalPlayedTimeLastYear: 1191*60*60))
        .body.environment(\.animated, false)
}

#Preview("Up") {
    YearOverYearCompare2025Story(subscriptionTier: .patron, listeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 203360, totalPlayedTimeLastYear: 173734))
        .body.environment(\.animated, false)
}

#Preview("Up - Max") {
    YearOverYearCompare2025Story(subscriptionTier: .plus, listeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 300000, totalPlayedTimeLastYear: 20000))
        .body.environment(\.animated, false)
}

#Preview("Same") {
    YearOverYearCompare2025Story(subscriptionTier: .patron, listeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 30000, totalPlayedTimeLastYear: 30000))
        .body.environment(\.animated, false)
}
