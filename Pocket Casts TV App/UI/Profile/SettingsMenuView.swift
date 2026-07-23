import SwiftUI
import PocketCastsServer

struct SettingsMenuView: View {

    @Environment(AppCoordinator.self) private var coordinator
    
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingTermsOfUse = false

    var body: some View {
        VStack {
            Button {
                isShowingPrivacyPolicy = true
            } label: {
                Text(L10n.accountPrivacyPolicy)
                    .frame(minWidth: 400)
            }
            Button {
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
            ShowQRLinkView(title: L10n.accountPrivacyPolicy, message: L10n.tvSettingsPrivacyPolicyQrMessage, urlString: ServerConstants.Urls.privacyPolicy)
                .onAppear {
                    Analytics.track(.accountDetailsShowPrivacyPolicy)
                }
        }
        .sheet(isPresented: $isShowingTermsOfUse) {
            ShowQRLinkView(title: L10n.termsOfUse, message: L10n.tvSettingsTermsOfUseQrMessage, urlString: ServerConstants.Urls.termsOfUse)
                .onAppear {
                    Analytics.track(.accountDetailsShowTOS)
                }
        }
        .remotePlayPause()
    }
}
