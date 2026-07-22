import SwiftUI
import PocketCastsServer

struct SettingsMenuView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingTermsOfUse = false


    var body: some View {
        VStack {
            Button() {

            } label: {
                Text("Subscription")
                    .frame(minWidth: 400)
            }
            Button() {
                isShowingPrivacyPolicy = true
            } label: {
                Text(L10n.accountPrivacyPolicy)
                    .frame(minWidth: 400)
            }
            Button() {
                isShowingTermsOfUse = true
            } label: {
                Text(L10n.termsOfUse)
                    .frame(minWidth: 400)
            }
        }
        .padding(80)
        .frame(width: 862, alignment: .center)
        .fixedSize(horizontal: true, vertical: false)
        .onAppear {
            Analytics.track(.settingsGeneralShown)
        }
        .sheet(isPresented: $isShowingPrivacyPolicy) {
            ShowHTMLView(title: L10n.accountPrivacyPolicy, urlString: ServerConstants.Urls.privacyPolicy)
                .environment(coordinator)
        }
        .sheet(isPresented: $isShowingTermsOfUse) {
            ShowHTMLView(title: L10n.termsOfUse, urlString: ServerConstants.Urls.termsOfUse)
                .environment(coordinator)
        }
        .remotePlayPause()
    }
}
