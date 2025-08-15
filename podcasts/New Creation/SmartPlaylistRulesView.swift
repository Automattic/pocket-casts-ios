import SwiftUI
import PocketCastsDataModel

struct SmartPlaylistRulesView: View {
    @EnvironmentObject var theme: Theme

    let viewModel: PlaylistPreviewViewModel

    var body: some View {
        switch viewModel.playlistMode {
        case .creation:
            if viewModel.isInPreview {

            } else {
                VStack(spacing: 24.0) {
                    Text("Set up Smart Rules to automatically add episodes to your Smart Playlist.")
                        .font(size: 14.0, style: .body, weight: .regular)
                        .lineLimit(2)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.leading)
                    SmartPlaylistRulesContainerView(
                        rules: viewModel.availableRules,
                        action: viewModel.action
                    )
                }
                .padding(.horizontal, 16.0)
            }
        case .edit:
            Text("")
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
            SmartPlaylistRulesView(
                viewModel: viewModel
            )
            .padding(.horizontal, 16.0)
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
            return filter
        }
    }

    return PreviewWrapper()
        .environmentObject(Theme.sharedTheme)
}
