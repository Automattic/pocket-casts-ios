import SwiftUI

struct EndOfYearModal: View {
    @EnvironmentObject var theme: Theme

    let year: Int

    struct ViewModel {
        let buttonTitle: String
        let description: String
        let backgroundImageName: String
    }

    let model: ViewModel

    var body: some View {
        VStack(spacing: 0) {
            ModalTopPill(fillColor: theme.activeTheme.isDark ? .white : .gray)
                .padding(.bottom, 28)

            VStack(alignment: .center, spacing: Constants.verticalSpacing) {

                Image(model.backgroundImageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(model.description)
                    .font(style: .callout, weight: .medium, maxSizeCategory: .accessibilityMedium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsTightening(false)
                    .padding(.bottom, Constants.verticalSpacing)

                showStoriesButton
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: Constants.maxWidth)
        .applyDefaultThemeOptions()
        .onAppear {
            Settings.setHasShownModalForEndOfYear(true, year: year)
            Analytics.track(.endOfYearModalShown)
        }
    }

    var showStoriesButton: some View {
        Button(model.buttonTitle) {
            NavigationManager.sharedManager.navigateTo(NavigationManager.endOfYearStories, data: nil)
        }
        .buttonStyle(RoundedDarkButton(theme: theme))
        .frame(height: 44)
    }

    private enum Constants {
        static let maxWidth: CGFloat = 600

        static let verticalSpacing: CGFloat = 20

        static let smallTitleFontSize: CGFloat = 14
        static let smallTitleTopPadding: CGFloat = -30
        static let smallTitleHorizontalPadding: CGFloat = 10
        static let smallTitleMinimumScaleFactor: CGFloat = 0.01

        static let enfOfYearCoverSize: CGFloat = 145
        static let coverCornerRadius: CGFloat = 8
        static let coverShadowRadius: CGFloat = 3
        static let coverShadowY: CGFloat = 1
    }
}

struct EndOfYearModal_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearModal(year: 2023, model: .init(buttonTitle: "View My Playback 2024", description: "See your playback for 2024", backgroundImageName: "modal_cover"))
            .environmentObject(Theme(previewTheme: .light))
    }
}
