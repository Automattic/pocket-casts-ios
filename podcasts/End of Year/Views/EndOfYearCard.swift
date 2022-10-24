import SwiftUI

struct EndOfYearCard: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: Constants.textSpace) {
                    Text(L10n.eoyTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(L10n.eoyCardDescription)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
                Image("2022_small")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.eoyImageSize.width,
                           height: Constants.eoyImageSize.height)
                    .padding(.trailing, 20)
            }
            .background(theme.activeTheme.isDark ? Constants.darkThemeBackgroundColor : Constants.lightThemeBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .padding()
    }

    private struct Constants {
        static let textSpace: CGFloat = 8

        static let eoyImageSize: CGSize = .init(width: 150, height: 150)
        static let eoyImageTopPadding: CGFloat = 20

        static let lightThemeBackgroundColor: Color = .black
        static let darkThemeBackgroundColor: Color = UIColor(hex: "#222222").color

        static let cornerRadius: CGFloat = 15
    }
}

struct EndOfYearCard_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearCard()
    }
}
