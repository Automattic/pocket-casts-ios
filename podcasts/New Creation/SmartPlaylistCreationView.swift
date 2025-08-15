import SwiftUI

struct SmartPlaylistCreationView: View {
    @EnvironmentObject var theme: Theme

    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        }  label: {
            HStack(spacing: 12.0) {
                Image("cs-sparkle-black")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(theme.primaryText01)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(L10n.playlistCreationCreateSmartPlaylistButtonTitle)
                        .font(size: 15.0, style: .body, weight: .medium)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.leading)
                    Text(L10n.playlistCreationCreateSmartPlaylistButtonSubtitle)
                        .font(size: 13.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                Image("cs-chevron")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryText02)
                    .frame(width: 24, height: 24)
            }
            .frame(minHeight: 59.0)
            .padding(.horizontal, 16.0)
        }
        .background(theme.primaryUi02Active)
        .cornerRadius(12.0)
    }
}
