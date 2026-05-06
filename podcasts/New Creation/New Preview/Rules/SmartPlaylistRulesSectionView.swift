import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SmartPlaylistRulesSectionView: View {
    @EnvironmentObject var theme: Theme

    let rules: [SmartPlaylistRuleInfo]
    let viewModel: PlaylistPreviewViewModel
    let action: (SmartPlaylistRule) -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = CGFloat(24)

    var body: some View {
        ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
            makeRow(for: rule)
                .padding(.horizontal, 32)
                .listRowInsets(EdgeInsets())
                .listRowBackground(
                    backgroundSlice(at: index)
                        .padding(.horizontal, 16)
                )
                .listRowSeparatorTint(theme.primaryUi05)
                .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
                .listRowSeparator(index == rules.count - 1 ? .hidden : .visible, edges: .bottom)
        }
    }

    @ViewBuilder
    private func makeRow(for rule: SmartPlaylistRuleInfo) -> some View {
        if rule.type.isMenuCompatible {
            pickerRow(for: rule.type)
        } else {
            Button {
                action(rule.type)
            } label: {
                makeRowLabel(for: rule)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Button Row

    private func makeRowLabel(for rule: SmartPlaylistRuleInfo) -> some View {
        HStack(alignment: .center) {
            Image(rule.type.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.primaryIcon03)
                .frame(width: iconSize, height: iconSize)
                .padding(.trailing, 8.0)

            Text(rule.type.title)
                .foregroundStyle(theme.primaryText01)
                .font(size: 17, style: .body)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack(spacing: 0) {
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
                    .padding(.trailing, -8)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Picker Row

    private func pickerRow(for rule: SmartPlaylistRule) -> some View {
        HStack(alignment: .center) {
            Image(rule.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.primaryIcon03)
                .frame(width: iconSize, height: iconSize)
                .padding(.trailing, 8.0)

            inlinePicker(for: rule)
        }
    }

    // MARK: - Background Slices

    private func backgroundSlice(at index: Int) -> some View {
        let isFirst = index == 0
        let isLast = index == rules.count - 1
        let radius: CGFloat = 8
        return UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: isFirst ? radius : 0,
                bottomLeading: isLast ? radius : 0,
                bottomTrailing: isLast ? radius : 0,
                topTrailing: isFirst ? radius : 0
            ),
            style: .continuous
        )
        .fill(theme.primaryUi02Active)
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
        .pickerStyle(.automatic)
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
        .pickerStyle(.automatic)
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
        .pickerStyle(.automatic)
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
        .pickerStyle(.automatic)
        .tint(theme.primaryText02)
    }
}

private enum DownloadStatusOption: Hashable {
    case all, downloaded, notDownloaded
}
