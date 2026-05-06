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

    var attributed: AttributedString {
        let baseString = L10n.tvSignInEnterCodeGoUrl("pocketcasts.com/pair", "https://pocketcasts.com/pair")
        var attributedString = (try? AttributedString(markdown: baseString)) ?? AttributedString(baseString)

        var linkStyle = AttributeContainer()
        linkStyle.foregroundColor = Color.textPrimary
        linkStyle.underlineStyle = .single

        for run in attributedString.runs where run.link != nil {
            attributedString[run.range].mergeAttributes(linkStyle)
        }
        return attributedString
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 32) {
                Spacer()
                Image(ImageResource.pcLogo)
                Text(L10n.tvSignInTitle)
                    .font(.title)
                Text(L10n.tvSignInSubtitle)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                if manualLogin {
                    usernamePasswordLogin
                } else {
                    QRCodeView()
                }
                Spacer()
                separator
                Text(L10n.tvSignInEnterCode)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                qrCodeDigits
                Text(attributed)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .task {
            if !manualLogin {
                model.signinWait()
            }
        }
        .onChange(of: model.state) {
            dismiss()
            coordinator.state = .userSync
        }
    }

    var qrCodeDigits: some View {
        HStack(spacing: 8) {
            ForEach(Array(model.codes.enumerated()), id: \.offset) { _, code in
                Text(code)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .padding()
                    .background(Color.backgroundActive50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    var separator: some View {
        Rectangle()
        .foregroundColor(.clear)
        .frame(width: 566, height: 1)
        .background(Color.textDisabled)

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
                .onSubmit { model.manualSignIn(username: username, password: password) }

            Button() {
                model.manualSignIn(username: username, password: password)
            } label: {
                Text("Sign In")
                    .frame(minWidth: 300)
            }
            .disabled(username.isEmpty || password.isEmpty)
        }
    }
}

#Preview {
    SignInView()
        .environment(AppCoordinator())
}
