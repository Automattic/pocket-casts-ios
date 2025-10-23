import SwiftUI

struct PlaylistArchiveView: View {
    @EnvironmentObject var theme: Theme

    @Binding private var isSelected: Bool
    @State private var refreshToken = UUID()
    private let episodesCount: Int

    init(
        episodesCount: Int,
        isSelected: Binding<Bool> = .constant(false)
    ) {
            self.episodesCount = episodesCount
            self._isSelected = isSelected
    }

    var body: some View {
        HStack {
            Text(L10n.podcastArchivedCountFormat(episodesCount))
                .font(size: 14.0, style: .footnote, weight: .regular)
                .foregroundColor(theme.primaryText02)
            Spacer()
            Button(action: {
                isSelected.toggle()
                refreshToken = UUID()
            }) {
                Text(isSelected ? L10n.podcastHideArchived : L10n.podcastShowArchived)
                    .font(size: 14.0, style: .footnote, weight: .medium)
                    .foregroundStyle(theme.primaryIcon01)
            }
            .buttonStyle(.plain)
            .id(refreshToken)
        }
        .background(theme.primaryUi02)
        .padding(.horizontal, 16.0)
    }
}

#Preview {
    PlaylistArchiveView(episodesCount: 4)
        .environmentObject(Theme.sharedTheme)
        .frame(height: 44)
}
