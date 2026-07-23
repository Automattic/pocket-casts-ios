import SwiftUI

struct ShowQRLinkView: View {
    let title: String
    let message: String
    let urlString: String

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text(title)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 800)
            }
            QRCodeView(url: urlString)
            Text(verbatim: urlString)
                .font(.caption)
                .foregroundStyle(Color.pcTextSecondary)
            Button(L10n.done) {
                dismiss()
            }
        }
        .padding(80)
        .remotePlayPause()
    }
}
