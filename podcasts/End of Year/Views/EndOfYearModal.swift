import SwiftUI

struct EndOfYearModal: View {
    @EnvironmentObject var theme: Theme

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(L10n.eoyTitle)
                .font(.title2)
                .fontWeight(.semibold)

            ZStack {
                Image("modal_background")
                    .resizable()
                ZStack {
                    VStack {
                        Image("2022_small")
                        Text(L10n.eoySmallTitle)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .padding(.top, -30)
                            .padding(.trailing, 10)
                            .padding(.leading, 10)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.01)
                    }
                    .frame(width: 145, height: 145)
                    .background(Color.black)
                    .cornerRadius(8)
                    .shadow(radius: 3, x: 0, y: 1)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(UIColor(hex: "#FF6262").color)
            .cornerRadius(16)

            Text(L10n.eoyDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .allowsTightening(false)

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
        .padding()
        .applyDefaultThemeOptions()
    }
}

struct EndOfYearModal_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearModal()
            .environmentObject(Theme(previewTheme: .light))
    }
}
