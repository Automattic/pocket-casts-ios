import SwiftUI
import PocketCastsUtils

struct StarRatingView: View {
    @EnvironmentObject var theme: Theme

    let rating: Double
    let total: Int?

    var body: some View {
        HStack(alignment: .center) {
            stars.foregroundColor(AppTheme.color(for: .filter03, theme: theme))

            if let total {
                Text(total.abbreviated)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .font(size: 14, style: .footnote)
                    .padding(.top, 1)
                    .monospacedDigit()
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var stars: some View {
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
        }
    }

    private func image(for index: Int, stars: Int, half: Double) -> Image {
        if index < stars {
            return Constants.filled
        }

        if index > stars {
            return Constants.empty
        }

        if half < 0.5 {
            return Constants.empty
        }

        return Constants.half
    }

    private enum Constants {
        static let maxStars = 5

        static let filled = Image(systemName: "star.fill")
        static let empty = Image(systemName: "star")
        static let half = Image(systemName: "star.fill.left")
    }
}
