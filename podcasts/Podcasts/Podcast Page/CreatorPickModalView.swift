import SwiftUI
import PocketCastsServer
import SafariServices

struct PodrollInformationModalView: View {
    @EnvironmentObject var theme: Theme
    var onDismiss: () -> Void

    let learnMoreURL: String = ServerConstants.Urls.podrollLearnMore

    var body: some View {
        VStack(spacing: 0) {
            ModalTopPill(fillColor: theme.activeTheme.isDark ? .white : .gray)

            VStack(spacing: 17) {
                Spacer().frame(height: 8)
                Image(systemName: "mic")
                    .resizable()
                    .scaledToFit()
                    .font(.system(size: 32, weight: .heavy))
                    .frame(width: 36, height: 36)
                    .foregroundColor(theme.primaryIcon01)
                    .padding(.top, 8)
                Text(L10n.creatorPickModalTitle)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText01)
                    .padding(.top, 8)
                Text(.init("\(L10n.creatorPickModalDescription) [\(L10n.creatorPickModalLearnMore)](\(learnMoreURL))"))
                    .font(.system(size: 14, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText02)
                    .padding(.horizontal, 22)
                    .tint(theme.primaryInteractive01)
                Spacer().frame(height: 8)
                Button(action: onDismiss) {
                    Text(L10n.gotIt)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .handleURLsWithSFSafariView()

            Spacer()
        }
    }
}
