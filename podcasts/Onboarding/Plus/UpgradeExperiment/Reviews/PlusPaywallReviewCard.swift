import SwiftUI

struct PlusPaywallReviewCard: View {
    let review: PlusPaywallReview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Constants.radius)
                    .fill(Constants.backgroundColor)
                VStack(alignment: .leading, spacing: Constants.vStackSpacing) {
                    HStack(spacing: 0) {
                        Text(review.title)
                            .font(size: Constants.fontSize, style: .body, weight: .medium)
                            .foregroundStyle(.white)
                        Spacer()
                        if let date = review.formattedDate {
                            Text(date, format: .dateTime.day().month())
                                .font(size: Constants.fontSize, style: .body)
                                .foregroundStyle(Constants.dateColor)
                        }
                    }
                    Text("★★★★★")
                        .font(size: Constants.fontSize, style: .body)
                        .foregroundColor(Constants.starsColor)
                    Text(review.review)
                        .font(size: Constants.fontSize, style: .body)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Constants.paddingH)
                .padding(.vertical, Constants.paddingV)
            }
        }
    }

    enum Constants {
        static let starsColor = Color(hex: "#FED443")
        static let backgroundColor = Color(hex: "#1A1C1E")
        static let dateColor = Color(hex: "#8F97A4")
        static let fontSize = 14.0
        static let radius = 10.0
        static let vStackSpacing = 6.0
        static let paddingH = 20.0
        static let paddingV = 16.0
    }
}

#Preview {
    ScrollView {
        LazyVStack(alignment: .center, spacing: 16.0) {
            ForEach(PlusPaywallReview.reviews, id: \.id) { review in
                PlusPaywallReviewCard(
                    review: PlusPaywallReview(
                        title: review.title,
                        review: review.review,
                        date: review.date)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20.0)
    }
    .background(.black)
    .frame(width: .infinity)
}
