import SwiftUI
import PocketCastsDataModel

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

    init() {
        UITableViewHeaderFooterView.appearance().backgroundView = UIView()
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: Podcast.previewPodcast().uuid)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Podcast title")
                            .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                        Text("Podcast • Author")
                            .font(size: 14, style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                    }
                    Spacer()
                    Image("close")
                }
                .listSectionSeparator(.hidden)
                .listRowSeparator(.visible)
                .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
                .zIndex(10)
                HStack(spacing: 12) {
                    Image("custom_search")
                        .frame(width: 48, height: 48)
                    Text("Search term")
                        .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                    Spacer()
                    Image("close")
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
                .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: Podcast.previewPodcast().uuid)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lower Cognitive Load - Pick Your Tools, Then Do Your Work")
                            .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                            .lineLimit(2)
                        Text("Episode • 1h 35min • Developer Tea")
                            .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image("close")
                }
                .listRowSeparator(.visible)
                    .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
            } header: {
                HStack {
                    Text("Recent searches")
                        .font(style: .title2, weight: .bold, maxSizeCategory: .extraExtraLarge)
                    Spacer()
                    Button("Clear all".uppercased()) {}
                        .font(style: .footnote, weight: .bold)
                        .foregroundColor(AppTheme.colorForStyle(.primaryInteractive01, themeOverride: theme.activeTheme).color)
                }
                .environment(\.defaultMinListHeaderHeight, 1)
                .listRowInsets(EdgeInsets(top: -30, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .background(AppTheme.colorForStyle(.primaryUi04, themeOverride: theme.activeTheme).color)
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
            .environmentObject(Theme(previewTheme: .rosé))
    }
}
