import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

// MARK: - SwiftUI View

struct SyncSigninView: View {
    @StateObject private var model: SyncSigninViewModel

    let coordinator: LoginCoordinator
    let loginAgain: Bool
    var onCompleted: (() -> Void)?

    init(coordinator: LoginCoordinator, loginAgain: Bool, onCompleted: (() -> Void)? = nil) {
        self.coordinator = coordinator
        self.loginAgain = loginAgain
        self.onCompleted = onCompleted
        self._model = StateObject(wrappedValue: SyncSigninViewModel(coordinator: coordinator))
    }

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
        .background(theme.primaryUi01)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(L10n.accountLogin)
        .onAppear {
            model.onCompleted = {
                onCompleted?() ?? dismiss()
            }
            model.onAppear(loginAgain: loginAgain)
            focusedField = .email
        }
        .onDisappear { model.onDisappear() }
    }

    private var promptColor: Color {
        theme.primaryField03
    }

    @ViewBuilder private func email() -> some View {
        HStack(spacing: 10) {
            Image("mail")
                .foregroundStyle(theme.primaryField03Active)
                .frame(width: 20)
            TextField(L10n.signInEmailAddressPrompt, text: $model.email, prompt: Text(L10n.signInEmailAddressPrompt).foregroundColor(promptColor))
                .font(.subheadline)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .password }
                .onChange(of: model.email) { _ in model.textFieldChanged() }
        }
        .padding(9)
        .themedTextField(hasErrored: model.errorMessage != nil)
    }

    @ViewBuilder private func password() -> some View {
        HStack(spacing: 10) {
            Image("key")
                .foregroundStyle(theme.primaryField03Active)
                .frame(width: 20)
            HStack(spacing: 8) {
                Group {
                    if model.showPassword {
                        TextField(L10n.signInPasswordPrompt, text: $model.password, prompt: Text(L10n.signInPasswordPrompt).foregroundColor(promptColor))
                    } else {
                        SecureField(L10n.signInPasswordPrompt, text: $model.password, prompt: Text(L10n.signInPasswordPrompt).foregroundColor(promptColor))
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
                .tint(theme.primaryIcon03)
            }
            .onChange(of: model.password) { _ in model.textFieldChanged() }
        }
        .padding(9)
        .themedTextField(hasErrored: model.errorMessage != nil)
    }

    @ViewBuilder private func forgotPassword() -> some View {
        Button(L10n.signInForgotPassword) {
            model.forgotPasswordTapped()
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryInteractive01)
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func signInButton() -> some View {
        Button {
            focusedField = nil
            model.performSignIn()
        } label: {
            ZStack {
                Text(L10n.signInContinueWithEmail)
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
        HStack(spacing: 15) {
            Rectangle()
                .foregroundStyle(theme.primaryUi05)
                .frame(height: 1)
            Text(L10n.signInDividerLabel)
                .font(.caption)
            Rectangle()
                .foregroundStyle(theme.primaryUi05)
                .frame(height: 1)
        }
    }
}

// MARK: - ViewModel

final class SyncSigninViewModel: ObservableObject {
    // Dependencies
    private let coordinator: LoginCoordinator

    // Inputs
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showPassword = false

    // UI state
    @Published var errorMessage: String?
    @Published var isSigningIn = false

    private var progressAlert: SyncLoadingAlert?

    var onCompleted: (() -> Void)?

    init(coordinator: LoginCoordinator) {
        self.coordinator = coordinator
    }

    // Progress tracking
    private var totalPodcastsToImport: Int = -1
    private var cancellables = Set<AnyCancellable>()

    var isValid: Bool {
        email.contains("@") && email.count >= 3 && password.count >= 3
    }

    func onAppear(loginAgain: Bool) {
        Analytics.track(.signInShown)

        NotificationCenter.default.publisher(for: ServerNotifications.syncProgressPodcastCount)
            .compactMap { $0.object as? NSNumber }
            .sink { [weak self] number in
                self?.totalPodcastsToImport = number.intValue
            }
            .store(in: &cancellables)

        // Note: SyncLoadingAlert handles progress notifications automatically via its own subscriptions

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

    func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        vc.delegate = self
        SceneHelper.rootViewController()?.navigationController?.pushViewController(vc, animated: true)
    }

    func performSignIn() {
        guard isValid else { return }
        startSignIn(username: email, password: password)
    }

    private func startSignIn(username: String, password: String) {
        isSigningIn = true
        errorMessage = nil

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
                    self.progressAlert?.hideAlert(false)
                    self.progressAlert = nil
                    return
                }

                // Show SyncLoadingAlert
                self.progressAlert = SyncLoadingAlert()
                if let navigationController = self.coordinator.navigationController {
                    self.progressAlert?.showAlert(navigationController, hasProgress: false, completion: nil)
                }

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
        progressAlert?.hideAlert(true) { [weak self] in
            self?.progressAlert = nil
            self?.onCompleted?()
        }
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

// MARK: - ForgotPassword delegate bridge

extension SyncSigninViewModel: ForgotPasswordDelegate {
    func handlePasswordResetSuccess() {
        // In the UIKit VC, it pops then shows an alert slightly later.
        // Here we mimic just the confirmation alert behavior.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if let rootVC = SceneHelper.rootViewController() {
                SJUIUtils.showAlert(
                    title: L10n.profileSendingResetEmailConfTitle,
                    message: L10n.profileSendingResetEmailConfMsg,
                    from: rootVC
                )
            }
        }
    }
}

#Preview {
    SyncSigninView(coordinator: LoginCoordinator(), loginAgain: false)
        .environmentObject(Theme(previewTheme: .light))
}
