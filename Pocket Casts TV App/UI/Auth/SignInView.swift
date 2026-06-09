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

    var enterCodePrompt: AttributedString {
        let baseString = L10n.tvSignInEnterCodeInUrl(model.pairURLPretty, model.pairURLString)
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
            VStack(spacing: 32) {
                Image(ImageResource.pcLogo)
                Text(L10n.tvSignInTitle)
                    .font(.title)
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
                VStack(spacing: 32) {
                    switch loginType {
                    case .manual:
                        usernamePasswordLogin
                            .padding(.top, 64)
                    case .qr:
                        if case .error(_, let message) = model.state {
                            qrCodeError(message: message)
                        } else {
                            Text(L10n.tvSignInSubtitle)
                                .font(.headline)
                                .foregroundStyle(Color.pcTextSecondary)
                            QRCodeView(url: model.pairURLString)
                            separator
                            Text(enterCodePrompt)
                                .font(.headline)
                                .foregroundStyle(Color.pcTextSecondary)
                            qrCodeDigits
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 80)
            .offset(y: -64)
        }
        .task(id: loginType) {
            // Clear any leftover error so it doesn't leak across login modes.
            model.state = .start
            switch loginType {
            case .qr:
                await model.thirdPartyApprovalSignin()
            case .manual:
                break
            }
        }
        .onChange(of: model.state) {
            if case .finished = model.state {
                dismiss()
                coordinator.state = .userSync
            }
        }
        .background(Color.pcBackgroundBase)
    }

    func qrCodeError(message: String) -> some View {
        ContentUnavailableView {
            Label(L10n.tvSignInQrCodeErrorTitle, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button {
                Task {
                    await model.thirdPartyApprovalSignin()
                }
            } label: {
                Text(L10n.tryAgain)
                    .frame(minWidth: 300)
            }
        }
        .padding(.top, 64)
    }

    var qrCodeDigits: some View {
        Group {
            if model.codes.isEmpty {
                ProgressView()
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(model.codes.enumerated()), id: \.offset) { _, code in
                        Text(code)
                            .font(.caption2)
                            .foregroundStyle(Color.pcTextSecondary)
                            .padding()
                            .background(Color.pcBackgroundActive20)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
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
            TextField("Username", text: $username)
                .textContentType(.username)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            SecureField("Password", text: $password)
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
                    Text("Sign In")
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
