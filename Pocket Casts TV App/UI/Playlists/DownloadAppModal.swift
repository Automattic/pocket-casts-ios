import SwiftUI

struct DownloadAppModal: View {
    @Environment(\.dismiss) private var dismiss

    private let downloadURL = "https://www.pocketcasts.com/downloads"

    var body: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text(L10n.tvPlaylistsDownloadTitle)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
                Text(L10n.tvPlaylistsDownloadSubtitle)
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 800)
            }
            QRCodeView(url: downloadURL)
            Text(verbatim: "pocketcasts.com/downloads")
                .font(.caption)
                .foregroundStyle(Color.pcTextSecondary)
            Button(L10n.done) {
                dismiss()
            }
        }
        .padding(80)
    }
}

#Preview {
    DownloadAppModal()
}
