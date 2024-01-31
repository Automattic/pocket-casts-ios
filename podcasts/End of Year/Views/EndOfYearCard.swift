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
                        .minimumScaleFactor(0.7)
                        .font(style: .title2, weight: .semibold, maxSizeCategory: .extraExtraLarge)
                        .foregroundColor(.white)

                    Text(L10n.eoyCardDescription)
                        .font(style: .footnote, weight: .semibold, maxSizeCategory: .accessibilityMedium)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
                Rectangle()
                    .frame(width: 150, height: 1)
                    .opacity(0)
            }
            .background {
                ZStack(alignment: .trailing) {
                    HStack {
                        Spacer()

                        Image("23_small")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.eoyImageSize.width * imageScale,
                                   height: Constants.eoyImageSize.height * imageScale)
                            .padding(.trailing, Constants.eoyImageTrailingPadding)
                            .offset(x: 40)
                    }
                }
            }
            .background(theme.activeTheme.isDark ? Constants.darkThemeBackgroundColor : Constants.lightThemeBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .padding()
    }

    private struct Constants {
        static let textSpace: CGFloat = 8

        static let eoyImageSize: CGSize = .init(width: 180, height: 180)
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
