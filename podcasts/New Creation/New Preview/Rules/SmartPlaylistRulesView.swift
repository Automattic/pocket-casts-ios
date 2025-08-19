import SwiftUI
import PocketCastsDataModel

struct SmartPlaylistRulesView: View {
    @State var isExpanded: Bool = false
    @EnvironmentObject var theme: Theme

    let viewModel: PlaylistPreviewViewModel

    var body: some View {
        switch viewModel.playlistMode {
        case .creation:
            if viewModel.isInPreview {
                VStack(alignment: .leading) {
                    if !viewModel.enabledRules.isEmpty {
                        Text(L10n.playlistSmartPreviewEnabledRules)
                            .font(size: 22.0, style: .body, weight: .bold)
                            .foregroundStyle(theme.primaryText01)
                        SmartPlaylistRulesContainerView(
                            rules: viewModel.enabledRules,
                            action: viewModel.action
                        )
                        .padding(.vertical, 16.0)
                    }
                    if !viewModel.availableRules.isEmpty {
                        DisclosureGroup(isExpanded: $isExpanded) {
                            SmartPlaylistRulesContainerView(
                                rules: viewModel.availableRules,
                                action: viewModel.action
                            )
                            .padding(.vertical, 16.0)
                        } label: {
                            Text(L10n.playlistSmartPreviewOtherRules)
                                .font(size: 22.0, style: .body, weight: .bold)
                                .foregroundStyle(theme.primaryText01)
                        }
                        .accentColor(theme.primaryIcon01)
                        .animation(.default, value: isExpanded)
                    }
                    // TODO: Remove this and move it into the episode section
                    Text(L10n.playlistPreviewTitle(viewModel.newPlaylist.playlistName))
                        .font(size: 22.0, style: .body, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                        .padding(.top, 16.0)
                    Spacer()
                }
                .padding(.horizontal, 16.0)
            } else {
                VStack(alignment: .leading) {
                    Text(viewModel.newPlaylist.playlistName)
                        .font(size: 22.0, style: .body, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                        .padding(.bottom, 2.0)
                    Text(L10n.playlistSmartPreviewDescription)
                        .font(size: 14.0, style: .body, weight: .regular)
                        .lineLimit(2)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 8.0)
                        .padding(.bottom, 24.0)
                    SmartPlaylistRulesContainerView(
                        rules: viewModel.availableRules,
                        action: viewModel.action
                    )
                }
                .padding(.horizontal, 16.0)
            }
        case .edit:
            SmartPlaylistRulesContainerView(
                rules: viewModel.availableRules,
                action: viewModel.action
            )
            .padding(.horizontal, 16.0)
        }
    }
}

struct SmartPlaylistRulesContainerView: View {
    @EnvironmentObject var theme: Theme

    let rules: [SmartPlaylistRuleInfo]
    let action: (SmartPlaylistRule) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rules) { rule in
                SmartPlaylistRuleRowView(
                    rule: rule.type,
                    description: rule.description,
                    hideDivider: rule.type == rules.last?.type,
                    action: action
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                .fill(theme.primaryUi02Active)
        )
    }
}

struct SmartPlaylistRuleRowView: View {
    @EnvironmentObject var theme: Theme

    let rule: SmartPlaylistRule
    let description: String?
    let hideDivider: Bool
    let action: (SmartPlaylistRule) -> Void

    var body: some View {
        Button {
            action(rule)
        } label: {
            ZStack {
                if !hideDivider {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(theme.primaryUi05)
                            .frame(height: 1)
                            .padding(.leading, 40)
                    }
                }
                HStack(alignment: .center) {
                    Image(rule.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(theme.primaryIcon03)
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 8.0)
                    Text(rule.title)
                        .foregroundStyle(theme.primaryText01)
                        .font(size: 17, style: .body)
                        .lineLimit(1)
                    Spacer()
                    if let description {
                        Text(description)
                            .foregroundStyle(theme.primaryText02)
                            .font(size: 17, style: .body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Image("cs-chevron")
                        .renderingMode(.template)
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 8.0)
                }
            }
            .padding(.leading, 16.0)
        }
        .frame(height: 44)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @EnvironmentObject var theme: Theme

        var body: some View {
            VStack {
                SmartPlaylistRulesView(
                    viewModel: viewModel
                )
                Spacer()
            }
        }

        private var viewModel: PlaylistPreviewViewModel {
            let viewModel = PlaylistPreviewViewModel(
                newPlaylist: model(),
                playlistMode: .creation) { _ in }
            return viewModel
        }

        private func model() -> EpisodeFilter {
            let filter = EpisodeFilter()
            filter.rawPlaylistType = 0
            filter.playlistName = "New Releases"
            filter.podcastSmartRuleApplied = true
            return filter
        }
    }

    return PreviewWrapper()
        .environmentObject(Theme.sharedTheme)
}
