import SwiftUI
import PocketCastsServer

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var showSubscriptionInfo = false

    var body: some View {
        VStack(spacing: 40) {
            Text(L10n.settings)
                .font(.title2)
                .foregroundStyle(Color.pcTextPrimary)

            VStack(spacing: 24) {
                if coordinator.userState.isPlusUser {
                    Button {
                        showSubscriptionInfo = true
                    } label: {
                        Label(L10n.tvSubscriptionInfoTitle, systemImage: "creditcard")
                            .frame(minWidth: 400)
                    }

                    Divider().frame(maxWidth: 400)
                }

                Link(destination: URL(string: ServerConstants.Urls.termsOfUse)!) {
                    Label(L10n.termsOfUse, systemImage: "doc.text")
                        .frame(minWidth: 400)
                }

                Link(destination: URL(string: ServerConstants.Urls.privacyPolicy)!) {
                    Label(L10n.aboutPrivacyPolicy, systemImage: "hand.raised")
                        .frame(minWidth: 400)
                }
            }
        }
        .padding(80)
        .frame(width: 862)
        .sheet(isPresented: $showSubscriptionInfo) {
            SubscriptionInfoView()
                .environment(coordinator)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppCoordinator())
}
