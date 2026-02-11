import AuthenticationServices
import SwiftUI
import PocketCastsUtils

// MARK: - YouTubePlaylistConnectView

/// OAuth sign-in screen for YouTube account connection
struct YouTubePlaylistConnectView: View {
    @EnvironmentObject private var theme: Theme

    @ObservedObject private var authManager = YouTubePlaylistAuthManager.shared

    /// Called after successful sign-in
    var onConnected: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                // Hero illustration
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(theme.primaryInteractive01)
                    .padding(.bottom, 32)

                // Heading
                Text("Connect YouTube")
                    .font(.largeTitle.bold())
                    .foregroundColor(theme.primaryText01)
                    .multilineTextAlignment(.center)

                Text("Sign in with your Google account to browse and play your YouTube playlists right inside Pocket Casts.")
                    .font(.body)
                    .foregroundColor(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer()

                // Error banner
                if let error = authManager.authError {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                }

                // Sign-in button
                signInButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
            .background(theme.primaryUi01.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var signInButton: some View {
        Button {
            Task { await signIn() }
        } label: {
            HStack(spacing: 10) {
                if authManager.isBusy {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                }
                Text(authManager.isBusy ? "Signing In…" : "Sign In with Google")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.primaryInteractive01)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(authManager.isBusy)
    }

    @MainActor
    private func signIn() async {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        let provider = WindowContextProvider(window: window)
        do {
            try await authManager.signIn(from: provider)
            onConnected()
        } catch YouTubePlaylistAuthError.canceled {
            // User dismissed; no error to show
        } catch {
            authManager.authError = error
        }
    }
}

// MARK: - Context Provider

private final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let window: UIWindow
    init(window: UIWindow) { self.window = window }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }
}
