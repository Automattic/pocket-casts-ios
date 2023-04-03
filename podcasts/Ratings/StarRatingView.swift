import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct StarRatingView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PodcastRatingViewModel

    /// Keeps track of when we appear to determine if we should animate
    private var startDate: Date = .now

    /// Only animate in if there's a rating and enough time has passed since appearing
    private var shouldAnimate: Bool {
        viewModel.rating != nil && Date().timeIntervalSince(startDate) > Constants.minTimeToAnimate
    }

    init(viewModel: PodcastRatingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(alignment: .center) {
            ratingView(rating: viewModel.rating)
                .animation(.easeIn, value: shouldAnimate)

            Spacer()
        }
    }

    @ViewBuilder
    private func ratingView(rating: PodcastRating?) -> some View {
        starsView(rating: rating?.average ?? 0)
        if viewModel.showTotal {
            labelView(total: rating?.total)
        }
    }

    @ViewBuilder
    private func starsView(rating: Double) -> some View {
        // truncate the floating points off without rounding
        let stars = Int(rating)
        // Get the float value
        let half = rating.truncatingRemainder(dividingBy: 1)

        HStack(spacing: 0) {
            ForEach(0..<Constants.maxStars, id: \.self) { index in
                image(for: index, stars: stars, half: half)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }.foregroundColor(AppTheme.color(for: .filter03, theme: theme))
    }

    @ViewBuilder
    private func labelView(total: Int?) -> some View {
        Text(total?.abbreviated ?? "")
            .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
            .font(size: 14, style: .footnote)
            .padding(.top, 1)
            .monospacedDigit()
    }

    private func image(for index: Int, stars: Int, half: Double) -> Image {
        if index < stars {
            return Constants.filled
        }

        if index > stars || half < 0.5 {
            return Constants.empty
        }

        return Constants.half
    }

    private enum Constants {
        /// How many total stars we want to show
        static let maxStars = 5

        // Star Images
        static let filled = Image(systemName: "star.fill")
        static let empty = Image(systemName: "star")
        static let half = Image(systemName: "star.fill.left")

        static let minTimeToAnimate: TimeInterval = 0.2
    }
}
