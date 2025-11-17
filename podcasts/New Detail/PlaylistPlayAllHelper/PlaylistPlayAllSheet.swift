import SwiftUI

struct PlaylistPlayAllSheet: View {
    @EnvironmentObject var theme: Theme

    weak var delegate: PlaylistPlayAllSheetHostDelegate?

    @Binding var isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image("playlist_picker_upnext_replace")
                .renderingMode(.template)
                .foregroundColor(theme.primaryIcon01)
                .frame(width: 36, height: 36)
                .padding(.bottom, 18.0)
            Text(L10n.playlistPlayAllSheetTitle)
                .font(.system(size: 23.0, weight: .bold))
                .foregroundColor(theme.primaryText01)
                .padding(.bottom, 8.0)
            Text(L10n.playlistPlayAllSheetDescription)
                .font(.system(size: 15.0))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.primaryText02)
            HStack {
                Text(L10n.playlistPlayAllSheetToggle)
                    .font(.system(size: 15.0))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(theme.primaryText02)
                    .padding(.leading, 16.0)
                Spacer()
                Toggle("", isOn: $isSelected)
                    .labelsHidden()
                    .tint(theme.primaryInteractive01)
                    .padding(.trailing, 16.0)
            }
            .background(
                RoundedRectangle(cornerRadius: 12.0)
                    .foregroundStyle(theme.primaryUi04)
                    .frame(height: 75.0)
            )
            .frame(height: 75.0)
            .padding(.vertical, 24.0)
            Button(action: playAll) {
                Text(L10n.playlistPlayAllSheetButtonTitle)
            }
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
            .frame(height: 56.0)
        }
        .background(theme.primaryUi01)
        .padding(.horizontal, 20.0)
    }

    private func playAll() {
        delegate?.onTapSaveAndReplace()
    }
}

#Preview {
    PlaylistPlayAllSheet(isSelected: .constant(true))
        .environmentObject(Theme(previewTheme: .light))
}
