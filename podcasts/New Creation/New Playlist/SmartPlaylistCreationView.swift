import SwiftUI

struct SmartPlaylistCreationView: View {
    @EnvironmentObject var theme: Theme

    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) var iconSize: CGFloat = 24

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
                    .frame(width: iconSize, height: iconSize)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(L10n.playlistCreationCreateSmartPlaylistButtonTitle)
                        .font(size: 15.0, style: .body, weight: .medium)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.leading)
                    Text(L10n.playlistCreationCreateSmartPlaylistButtonSubtitle)
                        .font(size: 13.0, style: .body, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 2.0)
                Spacer()
                Image("cs-chevron")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryText02)
                    .frame(width: iconSize, height: iconSize)
            }
            .frame(minHeight: 59.0)
            .padding(.horizontal, 16.0)
        }
        .background(theme.primaryUi02Active)
        .cornerRadius(12.0)
    }
}
