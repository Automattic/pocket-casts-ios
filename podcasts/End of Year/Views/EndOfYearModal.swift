import SwiftUI

struct EndOfYearModal: View {
    @EnvironmentObject var theme: Theme

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Your Year in Podcasts").font(.title3)
            Text("See your top podcasts, categories, listening stats, and more. Share with friends and shout out your favorite creators!")
                .multilineTextAlignment(.center)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
                NavigationManager.sharedManager.navigateTo(NavigationManager.endOfYearStories, data: nil)
            }) {
                HStack {
                    Spacer()
                    Text("View My 2022")
                    Spacer()
                }
            }
            .textStyle(RoundedButton())
            .contentShape(Rectangle())


            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Spacer()
                    Text("Not Now")
                    Spacer()
                }
            }
            .textStyle(RoundedButton())
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
