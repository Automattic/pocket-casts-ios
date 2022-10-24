import SwiftUI

struct EndOfYearModal: View {
    @EnvironmentObject var theme: Theme

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .center, spacing: Constants.verticalSpacing) {
            Text(L10n.eoyTitle)
                .font(.title2)
                .fontWeight(.semibold)

            cover

            Text(L10n.eoyDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .allowsTightening(false)

            showStoriesButton

            dismissButton
        }
        .padding()
        .applyDefaultThemeOptions()
    }

    var cover: some View {
        ZStack {
            Image("modal_background")
                .resizable()
            ZStack {
                VStack {
                    Image("2022_small")
                    Text(L10n.eoySmallTitle)
                        .foregroundColor(.white)
                        .font(.system(size: Constants.smallTitleFontSize))
                        .fontWeight(.semibold)
                        .padding(.top, Constants.smallTitleTopPadding)
                        .padding(.trailing, Constants.smallTitleHorizontalPadding)
                        .padding(.leading, Constants.smallTitleHorizontalPadding)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(Constants.smallTitleMinimumScaleFactor)
                }
                .frame(width: Constants.enfOfYearCoverSize, height: Constants.enfOfYearCoverSize)
                .background(Color.black)
                .cornerRadius(Constants.coverCornerRadius)
                .shadow(radius: Constants.coverShadowRadius, x: 0, y: Constants.coverShadowY)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.coverWrapperHeight)
        .cornerRadius(Constants.coverWrapperCornerRadius)
    }

    var showStoriesButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
            NavigationManager.sharedManager.navigateTo(NavigationManager.endOfYearStories, data: nil)
        }) {
            HStack {
                Spacer()
                Text(L10n.eoyViewYear)
                Spacer()
            }
        }
        .textStyle(RoundedDarkButton())
        .contentShape(Rectangle())
    }

    var dismissButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Spacer()
                Text(L10n.eoyNotNow)
                Spacer()
            }
        }
        .textStyle(StrokeButton())
        .contentShape(Rectangle())
    }

    private enum Constants {
        static let verticalSpacing: CGFloat = 20

        static let smallTitleFontSize: CGFloat = 14
        static let smallTitleTopPadding: CGFloat = -30
        static let smallTitleHorizontalPadding: CGFloat = 10
        static let smallTitleMinimumScaleFactor: CGFloat = 0.01

        static let enfOfYearCoverSize: CGFloat = 145
        static let coverCornerRadius: CGFloat = 8
        static let coverShadowRadius: CGFloat = 3
        static let coverShadowY: CGFloat = 1

        static let coverWrapperHeight: CGFloat = 180
        static let coverWrapperCornerRadius: CGFloat = 16
    }
}

struct EndOfYearModal_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearModal()
            .environmentObject(Theme(previewTheme: .light))
    }
}
