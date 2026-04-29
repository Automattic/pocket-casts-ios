import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SmartPlaylistRulesContainerView: View {
    @EnvironmentObject var theme: Theme

    let rules: [SmartPlaylistRuleInfo]
    let viewModel: PlaylistPreviewViewModel
    let action: (SmartPlaylistRule) -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = CGFloat(24)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rules, id: \.id) { rule in
                let isLast = rule.type == rules.last?.type
                if rule.type.isMenuCompatible {
                    SmartPlaylistRuleRowView(rule: rule.type, hideDivider: isLast) {
                        inlinePicker(for: rule.type)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(height: iconSize)
                            .padding(.trailing, 16.0)
                    }
                } else {
                    SmartPlaylistRuleRowView(rule: rule.type, hideDivider: isLast) {
                        if let description = rule.description {
                            Text(description)
                                .foregroundStyle(theme.primaryText02)
                                .font(size: 17, style: .body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Image("cs-chevron")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(theme.primaryIcon02)
                            .frame(width: iconSize, height: iconSize)
                            .padding(.trailing, 8.0)
                    }
                    .onTapGesture {
                        action(rule.type)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                .fill(theme.primaryUi02Active)
        )
    }

    // MARK: - Inline Pickers

    @ViewBuilder
    private func inlinePicker(for rule: SmartPlaylistRule) -> some View {
        switch rule {
        case .releaseDate:
            releaseDatePicker
        case .downloadStatus:
            downloadStatusPicker
        case .mediaType:
            mediaTypePicker
        case .starred:
            starredPicker
        case .episode:
            episodeStatusMenu
        default:
            EmptyView()
        }
    }

    private var releaseDatePicker: some View {
        let options: [ReleaseDateFilterOption] = [
            .anytime, .last24hours, .last3Days, .lastWeek, .last2Weeks, .lastMonth
        ]
        return Picker(selection: Binding(
            get: { ReleaseDateFilterOption(rawValue: viewModel.newPlaylist.filterHours) ?? .anytime },
            set: { newValue in
                viewModel.newPlaylist.filterHours = newValue.rawValue
                viewModel.newPlaylist.releaseDateSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "release_date")
            }
        )) {
            ForEach(options, id: \.self) { option in
                Text(option.description).tag(option)
            }
        } label: {
            Text(SmartPlaylistRule.releaseDate.title)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(theme.primaryText02)
    }

    private var downloadStatusPicker: some View {
        Picker(selection: Binding(
            get: {
                let filter = viewModel.newPlaylist
                if filter.filterDownloaded && !filter.filterNotDownloaded {
                    return DownloadStatusOption.downloaded
                } else if !filter.filterDownloaded && filter.filterNotDownloaded {
                    return DownloadStatusOption.notDownloaded
                } else {
                    return DownloadStatusOption.all
                }
            },
            set: { newValue in
                let filter = viewModel.newPlaylist
                switch newValue {
                case .all:
                    filter.filterDownloaded = true
                    filter.filterNotDownloaded = true
                case .downloaded:
                    filter.filterDownloaded = true
                    filter.filterNotDownloaded = false
                case .notDownloaded:
                    filter.filterDownloaded = false
                    filter.filterNotDownloaded = true
                }
                filter.downloadStatusSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "download_status")
            }
        )) {
            Text(L10n.filterValueAll).tag(DownloadStatusOption.all)
            Text(L10n.statusDownloaded).tag(DownloadStatusOption.downloaded)
            Text(L10n.statusNotDownloaded).tag(DownloadStatusOption.notDownloaded)
        } label: {
            Text(SmartPlaylistRule.downloadStatus.title)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(theme.primaryText02)
    }

    private var mediaTypePicker: some View {
        let options: [AudioVideoFilter] = [.all, .audioOnly, .videoOnly]
        return Picker(selection: Binding(
            get: { AudioVideoFilter(rawValue: viewModel.newPlaylist.filterAudioVideoType) ?? .all },
            set: { newValue in
                viewModel.newPlaylist.filterAudioVideoType = newValue.rawValue
                viewModel.newPlaylist.mediaTypeSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "audio_video")
            }
        )) {
            ForEach(options, id: \.self) { option in
                Text(option.description).tag(option)
            }
        } label: {
            Text(SmartPlaylistRule.mediaType.title)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(theme.primaryText02)
    }

    private var starredPicker: some View {
        Picker(selection: Binding(
            get: { viewModel.newPlaylist.filterStarred },
            set: { newValue in
                viewModel.newPlaylist.filterStarred = newValue
                viewModel.saveFilter(analyticsGroup: "starred")
            }
        )) {
            Text(L10n.on).tag(true)
            Text(L10n.off).tag(false)
        } label: {
            Text(SmartPlaylistRule.starred.title)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(theme.primaryText02)
    }

    @ViewBuilder
    private var episodeStatusMenu: some View {
        let unplayedBinding = Binding(
            get: { viewModel.newPlaylist.filterUnplayed },
            set: { newValue in
                if !newValue && !viewModel.newPlaylist.filterPartiallyPlayed && !viewModel.newPlaylist.filterFinished {
                    return
                }
                viewModel.newPlaylist.filterUnplayed = newValue
                viewModel.newPlaylist.episodesSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "episode_status")
            }
        )
        let inProgressBinding = Binding(
            get: { viewModel.newPlaylist.filterPartiallyPlayed },
            set: { newValue in
                if !newValue && !viewModel.newPlaylist.filterUnplayed && !viewModel.newPlaylist.filterFinished {
                    return
                }
                viewModel.newPlaylist.filterPartiallyPlayed = newValue
                viewModel.newPlaylist.episodesSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "episode_status")
            }
        )
        let playedBinding = Binding(
            get: { viewModel.newPlaylist.filterFinished },
            set: { newValue in
                if !newValue && !viewModel.newPlaylist.filterUnplayed && !viewModel.newPlaylist.filterPartiallyPlayed {
                    return
                }
                viewModel.newPlaylist.filterFinished = newValue
                viewModel.newPlaylist.episodesSmartRuleApplied = true
                viewModel.saveFilter(analyticsGroup: "episode_status")
            }
        )

        Menu {
            if #available(iOS 16.4, *) {
                Toggle(L10n.statusUnplayed, isOn: unplayedBinding)
                    .menuActionDismissBehavior(.disabled)
                Toggle(L10n.inProgress, isOn: inProgressBinding)
                    .menuActionDismissBehavior(.disabled)
                Toggle(L10n.statusPlayed, isOn: playedBinding)
                    .menuActionDismissBehavior(.disabled)
            } else {
                Toggle(L10n.statusUnplayed, isOn: unplayedBinding)
                Toggle(L10n.inProgress, isOn: inProgressBinding)
                Toggle(L10n.statusPlayed, isOn: playedBinding)
            }
        } label: {
            HStack(spacing: 4) {
                if let description = viewModel.ruleText(for: .episode) {
                    Text(description)
                        .font(size: 17, style: .body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.primaryText02)
        }
    }
}

private enum DownloadStatusOption: Hashable {
    case all, downloaded, notDownloaded
}
