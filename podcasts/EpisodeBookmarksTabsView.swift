import SwiftUI

/// Displays a fake set of tabs that allows the user to open the bookmarks view from the podcast list
struct EpisodeBookmarksTabsView: View {
    @EnvironmentObject var theme: Theme
    
    weak var delegate: PodcastActionsDelegate?
    
    var body: some View {
        HStack(spacing: 12) {
            Text(L10n.episodes).applyStyle(theme: theme)
            
            Text(L10n.bookmarks)
                .buttonize {
                    delegate?.showBookmarks()
                } customize: { config in
                    config.label
                        .applyStyle(theme: theme)
                        .applyButtonEffect(isPressed: config.isPressed)
                }
            
            Spacer()
        }
        .font(style: .subheadline, weight: .medium)
    }
}

struct EpisodeBookmarksTabsView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeBookmarksTabsView()
            .setupDefaultEnvironment()
    }
}

private extension View {
    func applyStyle(theme: Theme) -> some View {
        self
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(theme.primaryText02)
            .cornerRadius(8)
    }
}
