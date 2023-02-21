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
                ZStack {
                    Button(action: {
                        print("row tapped")
                    }) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(ListCellStyle())

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            PodcastCover(podcastUuid: Podcast.previewPodcast().uuid)
                                .frame(width: 48, height: 48)
                                .allowsHitTesting(false)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Podcast title")
                                    .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                                    .foregroundColor(AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color)
                                Text("Podcast • Author")
                                    .font(size: 14, style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                                    .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                            }
                            Spacer()
                            Button(action: {
                                print("tapped")
                            }) {
                                Image("close")
                            }
                            .buttonStyle(HighlightButtonStyle())
                            .frame(width: 48, height: 48)
                        }
                        Rectangle()
                            .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                            .frame(height: 0.5)
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        PodcastCover(podcastUuid: Podcast.previewPodcast().uuid)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Podcast title")
                                .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color)
                            Text("Podcast • Author")
                                .font(size: 14, style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                        }
                        Spacer()
                        Button(action: {
                            print("tapped")
                        }) {
                            Image("close")
                        }
                        .buttonStyle(HighlightButtonStyle())
                        .frame(width: 48, height: 48)
                    }
                    Rectangle()
                        .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                        .frame(height: 0.5)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
                .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image("custom_search")
                            .frame(width: 48, height: 48)
                        Text("Search term")
                            .font(style: .subheadline, weight: .medium, maxSizeCategory: .extraExtraLarge)
                        Spacer()
                        Image("close")
                            .frame(width: 48, height: 48)
                    }
                    Rectangle()
                        .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                        .frame(height: 0.5)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
                VStack(spacing: 12) {
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
                            .frame(width: 48, height: 48)
                    }
                    Rectangle()
                        .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                        .frame(height: 0.5)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
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

struct HighlightButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color : AppTheme.colorForStyle(.primaryIcon02, themeOverride: theme.activeTheme).color)
    }
}

struct ListCellStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppTheme.colorForStyle(.primaryUi02Active, themeOverride: theme.activeTheme).color : AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
    }
}
