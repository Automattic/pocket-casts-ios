import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

// MARK: - SwiftUI View

struct SyncSigninView: View {
    @StateObject private var model = SyncSigninViewModel()

    let coordinator: LoginCoordinator
    let dismissOnCancel: Bool
    let loginAgain: Bool
    var onCompleted: (() -> Void)?

    @EnvironmentObject var theme: Theme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                email()
                password()

                if let error = model.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }

                forgotPassword()

                signInButton()

                divider()

                SocialLoginButtons(coordinator: coordinator)

                // Add bottom padding to ensure content doesn't get cut off
                Color.clear.frame(height: 50)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(L10n.accountLogin)
        .onAppear {
            model.onCompleted = {
                onCompleted?() ?? dismiss()
            }
            model.onAppear(loginAgain: loginAgain)
        }
        .onDisappear { model.onDisappear() }
        .overlay {
            // Progress HUD replacement
            if model.showProgressHUD {
                ProgressHUDView(title: model.progressTitle, progress: model.progressValue)
            }
        }
    }

    @ViewBuilder private func email() -> some View {
        LabeledField(
            imageName: "mail",
            tint: AppTheme.colorForStyle(.primaryField03Active).swiftUIColor,
            isSelected: focusedField == .email,
            content: {
                TextField(L10n.signInEmailAddressPrompt, text: $model.email)
                    .font(.subheadline)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .onChange(of: model.email) { _ in model.textFieldChanged() }
            })
    }

    @ViewBuilder private func password() -> some View {
        LabeledField(
            imageName: "key",
            tint: AppTheme.colorForStyle(.primaryField03Active).swiftUIColor,
            isSelected: focusedField == .password,
            content: {
                HStack(spacing: 8) {
                    Group {
                        if model.showPassword {
                            TextField(L10n.signInPasswordPrompt, text: $model.password)
                        } else {
                            SecureField(L10n.signInPasswordPrompt, text: $model.password)
                        }
                    }
                    .font(.subheadline)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { model.performSignIn() }

                    Button(action: { model.toggleShowPassword() }) {
                        Image(model.showPassword ? "eye" : "eye-crossed")
                            .renderingMode(.template)
                    }
                    .accessibilityLabel(model.showPassword ? L10n.signInHidePasswordLabel : L10n.signInShowPasswordLabel)
                    .tint(ThemeColor.primaryIcon03().swiftUIColor)
                }
                .onChange(of: model.password) { _ in model.textFieldChanged() }
            })
    }

    @ViewBuilder private func forgotPassword() -> some View {
        Button(L10n.signInForgotPassword) {
            model.forgotPasswordTapped()
        }
        .buttonStyle(.plain)
        .foregroundStyle(ThemeColor.primaryInteractive01().swiftUIColor)
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func signInButton() -> some View {
        Button {
            focusedField = nil
            model.performSignIn()
        } label: {
            ZStack {
                Text("Continue with email")
                    .opacity(model.isSigningIn ? 0 : 1)
                if model.isSigningIn {
                    ProgressView().controlSize(.regular)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .buttonStyle(RoundedButtonStyle(theme: theme, isEnabled: model.isValid && !model.isSigningIn))
    }

    @ViewBuilder func divider() -> some View {
        HStack {
            Rectangle()
                .foregroundStyle(theme.primaryUi05)
                .frame(height: 1)
            Text(L10n.signInDividerLabel)
            Rectangle()
                .foregroundStyle(theme.primaryUi05)
                .frame(height: 1)
        }
    }
}

// MARK: - ViewModel

final class SyncSigninViewModel: ObservableObject {
    // Inputs
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showPassword = false

    // UI state
    @Published var errorMessage: String?
    @Published var isSigningIn = false
    @Published var showProgressHUD = false
    @Published var progressTitle: String = ""
    @Published var progressValue: Double? = nil // nil = indeterminate

    // Output callback (replaces delegate)
    var onCompleted: (() -> Void)?

    // Progress tracking
    private var totalPodcastsToImport: Int = -1
    private var cancellables = Set<AnyCancellable>()

    var isValid: Bool {
        email.contains("@") && email.count >= 3 && password.count >= 3
    }

    func onAppear(loginAgain: Bool) {
        Analytics.track(.signInShown)

        // Observers (using Combine)
        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressPodcastCount)
            .compactMap { $0.object as? NSNumber }
            .sink { [weak self] number in
                self?.totalPodcastsToImport = number.intValue
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressPodcastUpto)
            .compactMap { $0.object as? NSNumber }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] number in
                guard let self else { return }
                let upTo = number.intValue
                if totalPodcastsToImport > 0 {
                    progressTitle = L10n.syncProgress(upTo.localized(), totalPodcastsToImport.localized())
                    progressValue = Double(upTo) / Double(max(totalPodcastsToImport, 1))
                } else {
                    progressTitle = (upTo == 1) ? L10n.syncProgressUnknownCountSingular
                                               : L10n.syncProgressUnknownCountPluralFormat(upTo.localized())
                    progressValue = nil
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressImportedPodcasts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.progressTitle = L10n.syncInProgress
            }
            .store(in: &cancellables)

        // Complete on any of these
        let completions = [
            ServerNotifications.syncCompleted,
            ServerNotifications.syncFailed,
            ServerNotifications.podcastRefreshFailed
        ]
        Publishers.MergeMany(completions.map {
            NotificationCenter.default.publisher(for: $0)
        })
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.syncCompleted() }
        .store(in: &cancellables)

        // Auto-login if requested
        if loginAgain,
           let syncingEmail = ServerSettings.syncingEmail(),
           let password = ServerSettings.syncingPassword() {
            startSignIn(username: syncingEmail, password: password)
        }
    }

    func onDisappear() {
        cancellables.removeAll()
    }

    func toggleShowPassword() { showPassword.toggle() }

    func textFieldChanged() {
        errorMessage = nil
        // Button state reacts via @Published + computed isValid
    }

    func closeTapped(dismissOnCancel: Bool, dismiss: () -> Void) {
        Analytics.track(.signInDismissed)
        dismiss() // Both paths dismiss/pop in SwiftUI host
    }

    func forgotPasswordTapped() {
        // If you still use the UIKit VC, present here via a coordinator, or push a SwiftUI ForgotPasswordView.
        // Example: post a routing notification or set some @Published to show a sheet.
        // Keep for parity with existing app architecture:
        let vc = ForgotPasswordViewController()
        vc.delegate = self
        UIApplication.shared.topMostViewController()?.navigationController?.pushViewController(vc, animated: true)
    }

    func performSignIn() {
        guard isValid else { return }
        startSignIn(username: email, password: password)
    }

    private func startSignIn(username: String, password: String) {
        isSigningIn = true
        errorMessage = nil
        progressValue = nil

        // show "signing in..." spinner inline; progress HUD appears *after* success like the original
        ApiServerHandler.shared.validateLogin(username: username, password: password) { [weak self] success, userId, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if !success {
                    Analytics.track(.userSignInFailed, properties: [
                        "source": "password",
                        "error_code": (error ?? .UNKNOWN).rawValue
                    ])

                    if let err = error, err != .UNKNOWN, !err.localizedDescription.isEmpty {
                        self.errorMessage = err.localizedDescription
                    } else {
                        self.errorMessage = L10n.syncAccountError
                    }

                    self.isSigningIn = false
                    self.showProgressHUD = false
                    self.progressValue = nil
                    return
                }

                // Show progress HUD (replacing ShiftyLoadingAlert)
                self.progressTitle = L10n.syncAccountLogin
                self.showProgressHUD = true

                // Clear any previously stored tokens
                SyncManager.clearTokensFromKeyChain()
                FileLog.shared.addMessage("SyncSigninViewController.startSignIn clearTokensFromKeyChain")

                self.handleSuccessfulSignIn(username: username, password: password, userId: userId)

                RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
                Settings.setPromotionFinishedAcknowledged(true)
                Settings.setLoginDetailsUpdated()

                NotificationCenter.postOnMainThread(notification: .userSignedIn)
                self.isSigningIn = false
            }
        }
    }

    private func syncCompleted() {
        showProgressHUD = false
        progressValue = nil
        onCompleted?()
    }

    private func handleSuccessfulSignIn(username: String, password: String, userId: String?) {
        ServerSettings.userId = userId
        ServerSettings.saveSyncingPassword(password)

        if (FeatureFlag.onlyMarkPodcastsUnsyncedForNewUsers.enabled && ServerSettings.lastSyncTime == nil)
            || !FeatureFlag.onlyMarkPodcastsUnsyncedForNewUsers.enabled {
            DataManager.sharedManager.markAllPodcastsUnsynced()
        }

        SyncManager.syncReason = .login
        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: username)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)

        Analytics.track(.userSignedIn, properties: ["source": "password"])
    }
}

// MARK: - Small UI pieces

private struct LabeledField<Content: View>: View {
    let imageName: String
    let tint: Color
    let isSelected: Bool
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            Image(imageName)
                .foregroundStyle(tint)
                .frame(width: 20)
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                )
        )
    }
}

private struct ProgressHUDView: View {
    let title: String
    let progress: Double?

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                if let progress {
                    ProgressView(value: progress)
                } else {
                    ProgressView()
                }
                Text(title)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: 280)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: progress)
    }
}

// MARK: - Helpers

private extension UIColor {
    var swiftUIColor: Color { Color(self) }
}

private extension UIApplication {
    /// Helper used for pushing the existing UIKit ForgotPasswordViewController from SwiftUI.
    func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}

// MARK: - ForgotPassword delegate bridge

extension SyncSigninViewModel: ForgotPasswordDelegate {
    func handlePasswordResetSuccess() {
        // In the UIKit VC, it pops then shows an alert slightly later.
        // Here we mimic just the confirmation alert behavior.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if let top = UIApplication.shared.topMostViewController() {
                SJUIUtils.showAlert(
                    title: L10n.profileSendingResetEmailConfTitle,
                    message: L10n.profileSendingResetEmailConfMsg,
                    from: top
                )
            }
        }
    }
}
