import SwiftUI

struct SignInView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model = SignInViewModel()

    @Environment(\.dismiss) private var dismiss

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
                QRCodeView()
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
            model.signinWait()
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

}

#Preview {
    SignInView()
        .environment(AppCoordinator())
}
