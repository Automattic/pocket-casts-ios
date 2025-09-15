import SwiftUI

struct PlaylistHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistDetailViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                HStack {
                    Spacer()
                    PlaylistArtworkView(items: viewModel.images, imageSize: 192)
                        .frame(width: 192.0, height: 192.0)
                        .padding(.top, 5.0)
                        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 2)
                    Spacer()
                }

                VStack(spacing: 10.0) {
                    Text(viewModel.playlistName)
                        .font(style: .title2, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.center)
                    Text(L10n.playlistDetailDescription(viewModel.episodesCount, viewModel.totalDuration()))
                        .font(style: .footnote, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(theme.secondaryText02)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20.0)
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
                        title: L10n.playAll,
                        background: theme.primaryText01) { type in
                            viewModel.onButtonTapped(type)
                    }
                    Spacer()
                }

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
