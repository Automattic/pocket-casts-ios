import SwiftUI

struct SignInView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model = SignInViewModel()

    @Environment(\.dismiss) private var dismiss

    enum LoginType: Int, CaseIterable {
        case qr
        case manual

        var description: String {
            switch self {
            case .qr: L10n.tvUserSignInOptionQr
            case .manual: L10n.tvUserSignInOptionManual
            }
        }
    }

    @State private var loginType: LoginType = .qr

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 64) {
                Spacer()
                Text(L10n.tvSignInTitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(Color.pcTextPrimary)
                Picker(L10n.tvUserSignInLoginType, selection: $loginType) {
                    ForEach(LoginType.allCases, id: \.self) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 500)
                // Mode-specific content area, fixed height so the title
                // and picker above never shift when switching modes.
                VStack(spacing: 64) {
                    switch loginType {
                    case .manual:
                        usernamePasswordLogin
                    case .qr:
                        if case .error(_, let message) = model.pairing.state {
                            qrCodeError(message: message)
                        } else {
                            HStack(spacing: 64) {
                                QRCodeView(url: model.pairing.pairURLComplete)
                                StepList(steps: steps)
                            }
                            QRCodeDigits(digits: model.pairing.codes)
                        }
                    }
                }
                .animation(.easeInOut, value: loginType)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 80)
        }
        .task(id: loginType) {
            switch loginType {
            case .qr:
                await model.pairing.start()
            case .manual:
                // Clear any leftover error so it doesn't leak across login modes.
                model.state = .start
            }
        }
        .onChange(of: loginType) {
            Analytics.track(.signInTypeTapped, properties: ["type": loginType == .qr ? "qr" : "password"])
        }
        .onChange(of: model.state) {
            switch model.state {
            case .finished:
                finishSignIn(source: "password")
            case .error(let error, _):
                Analytics.track(.userSignInFailed, properties: ["source": "password", "error_code": (error as NSError).code])
            default:
                break
            }
        }
        .onChange(of: model.pairing.state) {
            switch model.pairing.state {
            case .finished:
                finishSignIn(source: "qr_code")
            case .error(let error, _):
                Analytics.track(.userSignInFailed, properties: ["source": "qr_code", "error_code": (error as NSError).code])
            default:
                break
            }
        }
        .background(Color.pcBackgroundBase)
    }

    var steps: [String] {
        [
            L10n.tvCreateAccountStepScan(model.pairing.pairURLPretty),
            L10n.tvCreateAccountStepLogin,
            L10n.tvCreateAccountStepConfirmCode
        ]
    }

    private func finishSignIn(source: String) {
        Analytics.track(.userSignedIn, properties: ["source": source])
        dismiss()
        coordinator.state = .userSync
    }

    func qrCodeError(message: String) -> some View {
        ContentUnavailableView {
            Label(L10n.tvLogInQrCodeErrorTitle, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button {
                Task {
                    await model.pairing.start()
                }
            } label: {
                Text(L10n.tryAgain)
                    .frame(minWidth: 300)
            }
        }
        .padding(.top, 64)
    }

    @FocusState private var focusedField: Field?

    enum Field {
        case username, password
    }

    @State private var username = ""
    @State private var password = ""

    var usernamePasswordLogin: some View {
        VStack(spacing: 32) {
            TextField(L10n.tvUserSignInUsernamePlaceholder, text: $username)
                .textContentType(.username)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            SecureField(L10n.signInPasswordPrompt, text: $password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await model.manualSignIn(username: username, password: password)
                    }
                }
            if case .error(_, let errorMessage) = model.state {
                Text(errorMessage)
            }
            Button() {
                Task {
                    await model.manualSignIn(username: username, password: password)
                }
            } label: {
                switch model.state {
                case .start, .error:
                    Text(L10n.accountLogin)
                        .frame(minWidth: 300)
                case .waiting:
                    ProgressView()
                        .accessibilityLabel(L10n.tvUserSignInSigningIn)
                default:
                    EmptyView()
                }
            }
            .disabled(username.isEmpty || password.isEmpty || model.state == .waiting)
        }
        .frame(maxWidth: 500)
    }
}

#Preview {
    SignInView()
        .environment(AppCoordinator())
}
