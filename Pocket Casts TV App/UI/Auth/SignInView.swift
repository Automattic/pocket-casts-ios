import SwiftUI

struct SignInView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model = SignInViewModel()

    @Environment(\.dismiss) private var dismiss

    let manualLogin: Bool = true

    enum Layout {
        static let gridSize = CGFloat(272)
        static let qrSize = CGFloat(240)
    }

    func enterCodePrompt(url: String) -> AttributedString {
        let baseString = L10n.tvSignInEnterCodeInUrl(model.pairing.pairURLPretty, url)
        var attributedString = (try? AttributedString(markdown: baseString)) ?? AttributedString(baseString)

        var linkStyle = AttributeContainer()
        linkStyle.foregroundColor = Color.pcTextPrimary
        linkStyle.underlineStyle = .single

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].mergeAttributes(linkStyle)
        }
        return attributedString
    }

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
                // Mode-specific content area, fixed height so the logo,
                // title, and picker above never shift when switching modes.
                VStack(spacing: 64) {
                    switch loginType {
                    case .manual:
                        usernamePasswordLogin
                            .padding(.top, 64)
                    case .qr:
                        if case .error(_, let message) = model.pairing.state {
                            qrCodeError(message: message)
                        } else {
                            HStack {
                                QRCodeView(url: model.pairing.pairURLComplete)
                                fullScreenSteps
                            }
                            QRCodeDigits(digits: model.pairing.codes)
                        }
                    }
                }
                .animation(.easeInOut, value: loginType)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 80)
            .offset(y: -64)
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
    @ViewBuilder
    private var fullScreenSteps: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepBadge(number: index + 1, text: step)
            }
        }
    }

    private func stepBadge(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption2)
                .foregroundStyle(Color.pcTextSecondary)
                .frame(width: 40, height: 40)
                .background(Color.pcBackgroundActive20, in: Circle())
            Text(text)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        // Read each step as a single unit rather than landing on the bare badge.
        .accessibilityElement(children: .combine)
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

    var separator: some View {
        Rectangle()
        .foregroundColor(.clear)
        .frame(width: 566, height: 1)
        .background(Color.pcTextDisabled)
    }

    @FocusState private var focusedField: Field?

    enum Field {
        case username, password
    }

    @State private var username = ""
    @State private var password = ""

    var usernamePasswordLogin: some View {
        VStack {
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
