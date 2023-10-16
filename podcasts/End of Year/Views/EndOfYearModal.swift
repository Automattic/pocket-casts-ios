import SwiftUI

struct EndOfYearModal: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            ModalTopPill(fillColor: theme.activeTheme.isDark ? .white : .gray)
                .padding(.bottom, 28)

            VStack(alignment: .center, spacing: Constants.verticalSpacing) {

                Image("modal_cover")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(L10n.eoyDescription)
                    .font(style: .body, weight: .medium, maxSizeCategory: .accessibilityMedium)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsTightening(false)
                    .padding(.bottom, Constants.verticalSpacing)

                showStoriesButton
            }
            .padding()
        }
        .frame(maxWidth: Constants.maxWidth)
        .applyDefaultThemeOptions()
        .onAppear {
            Settings.endOfYearModalHasBeenShown = true
            Analytics.track(.endOfYearModalShown)
        }
    }

    var showStoriesButton: some View {
        Button(L10n.eoyViewYear) {
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
        EndOfYearModal()
            .environmentObject(Theme(previewTheme: .light))
    }
}
