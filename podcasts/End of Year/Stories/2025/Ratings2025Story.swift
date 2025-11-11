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

    @State var scale: Double = 1
    @State var openURL = false

    var body: some View {
        Group {
            if ratings.count == 0 {
                emptyView()
            } else {
                ZStack {
                    chartView()
                    VStack(spacing: 0) {
                        Spacer()
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
                            .frame(height: 120)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .foregroundStyle(foregroundColor)
        .background(
            backgroundColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
        .onAppear {
            if animated {
                setInitialCoverOffsetForAnimation()
            }
        }
    }

    private func setInitialCoverOffsetForAnimation() {
        scale = 0
    }

    @ViewBuilder func columnsView() -> some View {
        VStack(spacing: 0) {
            StoryHeader2025(
                title: descriptionText(),
                description: "Creators everywhere appreciate the love"
            )
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder func emptyView() -> some View {
        VStack(spacing: 0) {
            StoryHeader2025(
                title: "No ratings yet, but there's still time!",
                description: "Help your favorite creators get discovered by sharing what you love"
            )
            Spacer()
            Button(L10n.learnAboutRatings) {
                pauseState.togglePause()
                openURL = true
                Analytics.track(.endOfYearLearnRatingsShown, properties: ["year": "2025"])
            }
            .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
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

//    @ViewBuilder func chartView() -> some View {
//        GeometryReader { geometry in
//            HStack(alignment: .bottom) {
//                let maxRating = ratings.values.max() ?? 0
//                ForEach(ratingScale, id: \.self) { ratingGroup in
//                    let count = ratings[UInt32(ratingGroup)] ?? 0
//                    VStack {
//                        Text("\(ratingGroup)")
//                            .font(.system(size: 22, weight: .semibold))
//                            .opacity(scale)
//                            .offset(x: 0, y: 10 * (1 - scale))
//                        DashedRectangle()
//                            .frame(height: max(geometry.size.height * (CGFloat(count) / CGFloat(maxRating)), 5))
//                            .scaleEffect(x: 1, y: scale, anchor: .bottom)
//                    }
//                }
//            }
//        }
//    }

    @ViewBuilder func chartView() -> some View {
        VStack(spacing: 0) {
            StoryHeader2025(
                title: descriptionText(),
                description: "Creators everywhere appreciate the love"
            )
            GeometryReader { geometry in
                let maxRating = ratings.values.max() ?? 0
                let columnWidth = geometry.size.width / CGFloat(ratingScale.count)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(ratingScale, id: \.self) { ratingGroup in
                        ChartColumn(
                            value: ratings[UInt32(ratingGroup)] ?? 0,
                            maxValue: maxRating,
                            index: ratingGroup
                        )
                            .frame(width: columnWidth)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 50)
            }
        }
    }

    private func descriptionText() -> String {
        switch mostCommonRating {
        case 1...3:
            return "Thanks for sharing your feedback.\nReviews help great shows get found"
        case 4...5:
            return "You dropped \(mostCommonRating)-star ratings like confetti"
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
        LottieView(animation: .named("2025_rating"))
            .configure({ animationView in
                animationView.contentMode = .scaleToFill
                animationView.logHierarchyKeypaths()

//                animationView.textProvider = MyLottieTextProvider()
//                animationView.fontProvider = MyFontProvider()
            })
            .playbackMode(
                .playing(
                    .marker(marker(for: value, maxValue: maxValue),
                            loopMode: .playOnce
                           )
                )
            )
            .scaledToFill()
            .ignoresSafeArea()
    }

    func marker(for value: Int, maxValue: Int, step: Int = 10) -> String {
        guard maxValue > 0 else { return "marker_10" }

        let percentage = Double(value) / Double(maxValue) * 100

        // Compute reversed bucket from 10 (worst) to 1 (best)
        let bucket = 10 - Int((percentage / 10).rounded(.down))
        let clamped = min(max(bucket, 1), 10)

        return "marker_\(clamped)"
    }
}

#Preview {
    Ratings2025Story(ratings: [1: 3, 2: 0, 3: 0, 4: 7, 5: 2])
}
