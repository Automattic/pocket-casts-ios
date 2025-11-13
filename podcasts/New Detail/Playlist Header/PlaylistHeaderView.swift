import SwiftUI

struct PlaylistHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistDetailViewModel

    var description: String {
        let duration = viewModel.totalDuration()
        switch viewModel.playlistEpisodesCount {
        case let count where count > 1:
            if let duration {
                return L10n.playlistDetailDescription(count, duration)
            }
            return L10n.playlistEpisodesCount(count)
        case 1:
            if let duration {
                return L10n.playlistDetailDescriptionOneEpisode(duration)
            }
            return L10n.podcastEpisodeCountSingular
        default:
            return L10n.playlistEpisodesCount(viewModel.playlistEpisodesCount)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    PlaylistArtworkView(items: viewModel.images, cornerRadius: 8)
                        .frame(width: 192.0, height: 192.0)
                        .padding(.top, 15.0)
                        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 2)
                    Spacer()
                }

                VStack(spacing: 0.0) {
                    Text(viewModel.playlistName)
                        .font(style: .title2, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10.0)
                    Text(description)
                        .font(style: .footnote, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 15.0)
                .padding(.bottom, 16.0)

                HStack(spacing: 8.0) {
                    Spacer()
                    actionButton(
                        type: viewModel.isManualPlaylist ? .addEpisodes : .smartRules,
                        color: theme.primaryText01,
                        image: Image(viewModel.isManualPlaylist ? "filter_new_episode" : "cs-sparkle-black"),
                        title: viewModel.isManualPlaylist ? L10n.playlistManualAddEpisodes : L10n.playlistSmartRulesTitle,
                        background: .clear,
                        stroke: theme.primaryUi05) { type in
                            viewModel.onButtonTapped(type)
                    }
                    actionButton(
                        type: .playAll,
                        color: theme.primaryUi02,
                        image: Image("filter_play"),
                        title: L10n.playlistsPlayAll,
                        background: theme.primaryText01) { type in
                            viewModel.onButtonTapped(type)
                    }
                    Spacer()
                }
                .padding(.bottom, 10.0)

                Spacer()
            }
        }
        .background(.clear)
    }

    private func actionButton(
        type: PlaylistDetailViewModel.ButtonTag,
        color: Color,
        image: Image,
        title: String,
        background: Color,
        stroke: Color? = nil,
        action: @escaping (PlaylistDetailViewModel.ButtonTag) -> Void
    ) -> some View {
        Button {
            action(type)
        } label: {
            HStack(alignment: .top, spacing: 8.0) {
                image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(color)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundStyle(color)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 10.0)
            .frame(minWidth: 152, minHeight: 40.0)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(stroke ?? background, lineWidth: 2)
            )
        }
    }
}
