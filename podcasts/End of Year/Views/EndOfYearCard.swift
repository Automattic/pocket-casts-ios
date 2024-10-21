import SwiftUI
import PocketCastsUtils

struct EndOfYearCard: View {
    @EnvironmentObject var theme: Theme

    let viewModel: ViewModel

    struct ViewModel {
        let title: String
        let description: String
        let imageName: String
        let imagePadding: CGFloat
    }

    private var imageScale: Double {
        A11y.isDisplayZoomed ? 0.75 : 1.0
    }

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: Constants.textSpace) {
                    Text(viewModel.title)
                        .minimumScaleFactor(0.7)
                        .font(style: .title2, weight: .semibold, maxSizeCategory: .extraExtraLarge)
                        .foregroundColor(.white)

                    Text(viewModel.description)
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

                        Image(viewModel.imageName)
                            .padding(.trailing, viewModel.imagePadding)
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

        static let lightThemeBackgroundColor: Color = UIColor(hex: "#1A1A1A").color
        static let darkThemeBackgroundColor: Color = UIColor(hex: "#222222").color

        static let cornerRadius: CGFloat = 15
    }
}

struct EndOfYearCard_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearCard(viewModel: .init(title: "Playback 2024", description: "See your last 2024 playback", imageName: "23_small", imagePadding: 20))
            .environmentObject(Theme(previewTheme: .light))
    }
}
