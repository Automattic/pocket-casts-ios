import SwiftUI
import PocketCastsUtils

struct EndOfYearCard: View {
    @EnvironmentObject var theme: Theme

    private var imageScale: Double {
        A11y.isDisplayZoomed ? 0.75 : 1.0
    }

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: Constants.textSpace) {
                    Text(L10n.eoyTitle)
                        .font(style: .title2, weight: .semibold, maxSizeCategory: .extraExtraLarge)
                        .foregroundColor(.white)

                    Text(L10n.eoyCardDescription)
                        .font(style: .footnote, weight: .semibold, maxSizeCategory: .accessibilityMedium)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
                Image("2022_small")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.eoyImageSize.width * imageScale,
                           height: Constants.eoyImageSize.height * imageScale)
                    .padding(.trailing, Constants.eoyImageTrailingPadding)
            }
            .background(theme.activeTheme.isDark ? Constants.darkThemeBackgroundColor : Constants.lightThemeBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .padding()
    }

    private struct Constants {
        static let textSpace: CGFloat = 8

        static let eoyImageSize: CGSize = .init(width: 150, height: 150)
        static let eoyImageTrailingPadding: CGFloat = 20

        static let lightThemeBackgroundColor: Color = UIColor(hex: "#1A1A1A").color
        static let darkThemeBackgroundColor: Color = UIColor(hex: "#222222").color

        static let cornerRadius: CGFloat = 15
    }
}

struct EndOfYearCard_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearCard()
            .environmentObject(Theme(previewTheme: .light))
    }
}
