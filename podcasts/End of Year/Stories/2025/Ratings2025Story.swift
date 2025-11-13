import SwiftUI
import Lottie

struct Ratings2025Story: ShareableStory {

    let ratingScale = 1...5
    let ratings: [UInt32: Int]

    let foregroundColor: Color = .white
    let backgroundColor: Color = Color(hex: "#A22828")
    private let ratingsBlogPostURL = URL(string: "https://blog.pocketcasts.com/2024/08/20/podcast-ratings/")!

    @Environment(\.animated) var animated: Bool
    @Environment(\.pauseState) var pauseState

    let identifier: String = "ratings"

    @State var openURL = false

    var body: some View {
        Group {
            if ratings.count == 0 {
                emptyView()
                // TODO: for empty rating values, we can just load the same chart view with 0 rating passed avoiding play it. It should automatically load the correct marker to keep it at the bottom
            } else {
                columnsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(foregroundColor)
        .ignoresSafeArea()
        .background(backgroundColor)
    }

    @ViewBuilder func columnsView() -> some View {
        VStack(spacing: 0) {
            StoryHeader2025(
                title: titleText,
                description: descriptionText
            )
            .padding(.horizontal, 24)
            Spacer()
            ZStack(alignment: .bottom) {
                chartView()
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: backgroundColor.opacity(1.0), location: 0),
                                .init(color: backgroundColor.opacity(0.0), location: 1)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 60)
            }
        }
    }

    @ViewBuilder func emptyView() -> some View {
        VStack(spacing: 0) {
            StoryHeader2025(
                title: L10n.playback2025RatingsEmptyTitle,
                description: L10n.playback2025RatingsEmptyDescription
            )
            Spacer()
            Button(L10n.learnAboutRatings) {
                pauseState.togglePause()
                openURL = true
                Analytics.track(.endOfYearLearnRatingsShown, properties: ["year": "2025"])
            }
            .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.white, borderColor: .white))
            .allowsHitTesting(true)
        }
        .sheet(isPresented: $openURL, onDismiss: {
            pauseState.togglePause()
            openURL = false
        }, content: {
            SFSafariView(url: ratingsBlogPostURL)
        })
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    @ViewBuilder func chartView() -> some View {
        GeometryReader { geometry in
            let maxRating = ratings.values.max() ?? 0
            let columnWidth = geometry.size.width / CGFloat(ratingScale.count)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(ratingScale, id: \.self) { ratingGroup in
                    ZStack {
                        ChartColumn(
                            value: ratings[UInt32(ratingGroup)] ?? 0,
                            maxValue: maxRating,
                            index: ratingGroup
                        )
                        Text(ChartColumn.marker(for: ratings[UInt32(ratingGroup)] ?? 0, maxValue: maxRating))
                    }
                    .frame(width: columnWidth, height: geometry.size.height)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
    }

    private var titleText: String {
        switch mostCommonRating {
        case 1...3:
            return L10n.playback2025RatingsTitle1To3
        case 4...5:
            return L10n.playback2025RatingsTitle4To5("\(mostCommonRating)")
        default:
            return ""
        }
    }

    private var descriptionText: String {
        switch mostCommonRating {
            case 1...3:
                return L10n.playback2025RatingsDescription1To3
            case 4...5:
                return L10n.playback2025RatingsDescription4To5
            default:
                return ""
        }
    }

    private var mostCommonRating: UInt32 {
        ratings.max(by: { $0.value < $1.value })?.key ?? 0
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        let totalRatings = ratings.values.reduce(0, +)
        return [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearRatingsShareText(totalRatings, "2025", mostCommonRating), year: .y2025)
        ]
    }

    func hideShareButton() -> Bool {
        ratings.count == 0
    }
}

fileprivate struct ChartColumn: View {
    let value: Int
    let maxValue: Int
    let index: Int

    var body: some View {
        ZStack {
            LottieView(animation: .named("2025_rating_bars"))
                .configure({ animationView in
                    animationView.contentMode = .scaleToFill
                    animationView.textProvider = LottieTextProvider(index: index)
                    animationView.fontProvider = LottieFontProvider()
                })
                .playbackMode(
                    .playing(
                        .marker(Self.marker(for: value, maxValue: maxValue),
                                loopMode: .playOnce
                               )
                    )
                )
            LottieView(animation: .named("2025_rating_numbers"))
                .configure({ animationView in
                    animationView.contentMode = .scaleAspectFit
                    animationView.textProvider = LottieTextProvider(index: index)
                    animationView.fontProvider = LottieFontProvider()
                })
                .playbackMode(
                    .playing(
                        .marker(Self.marker(for: value, maxValue: maxValue),
                                loopMode: .playOnce
                               )
                    )
                )
        }
    }

    static func marker(for value: Int, maxValue: Int, step: Int = 10) -> String {
        guard maxValue > 0 else { return "marker_10" }

        let percentage = Double(value) / Double(maxValue) * 100

        // Compute reversed bucket from 10 (worst) to 1 (best)
        let bucket = 10 - Int((percentage / 10).rounded(.down))
        let clamped = min(max(bucket, 1), 10)

        return "marker_\(clamped)"
    }
}

final private class LottieTextProvider: LegacyAnimationTextProvider, Equatable {
    private let index: Int

    private static func formatted(hours: Int) -> String {
        return hours == 1 ? L10n.hoursSingularFormat : L10n.hoursPluralFormat(hours)
    }

    init(
        index: Int
    ) {
        self.index = index
    }

    func textFor(keypathName: String, sourceText: String) -> String {
        return "\(index)"
    }

    static func == (lhs: LottieTextProvider, rhs: LottieTextProvider) -> Bool {
        lhs.index == rhs.index
    }
}

fileprivate class LottieFontProvider: AnimationFontProvider {
    func fontFor(family: String, size: CGFloat) -> CTFont? {
        let font = UIFont(name: family, size: 38)!
        return CTFontCreateWithName("Inter-Regular_Semibold" as CFString, font.pointSize, nil)
    }
}

#Preview("Ratings 1-3") {
    Ratings2025Story(ratings: [1: 100, 2: 50, 3: 30, 4: 15, 5: 5])
}

#Preview("Ratings 4-5") {
    Ratings2025Story(ratings: [1: 5, 2: 20, 3: 30, 4: 40, 5: 80])
}

#Preview("No Ratings") {
    Ratings2025Story(ratings: [:])
}
