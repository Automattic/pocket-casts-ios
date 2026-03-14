import SwiftUI

struct EpisodeTitleFilterHeaderView: View {
    @EnvironmentObject var theme: Theme
    @State private var titleText: String

    let onTitleChanged: (String) -> Void

    init(currentTitle: String, onTitleChanged: @escaping (String) -> Void) {
        self._titleText = State(initialValue: currentTitle)
        self.onTitleChanged = onTitleChanged
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(L10n.filterEpisodeTitleContainsHeader)
                .font(size: 18.0, style: .body, weight: .semibold)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(theme.primaryText01)

            Text(L10n.filterEpisodeTitleContainsDescription)
                .font(size: 14.0, style: .body, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(theme.primaryText02)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.primaryText02)

                TextField(L10n.filterEpisodeTitleContainsPlaceholder, text: $titleText)
                    .font(size: 16.0, style: .body)
                    .foregroundStyle(theme.primaryText01)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: titleText) { newValue in
                        onTitleChanged(newValue)
                    }

                if !titleText.isEmpty {
                    Button {
                        titleText = ""
                        onTitleChanged("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.primaryText02)
                    }
                }
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 10.0)
            .background(
                RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                    .fill(theme.primaryUi02Active)
            )
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 10.0)
        .padding(.bottom, 22.0)
        .background(theme.primaryUi01)
    }
}
