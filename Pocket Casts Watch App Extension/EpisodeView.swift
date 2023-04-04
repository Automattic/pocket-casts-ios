import Kingfisher
import PocketCastsDataModel
import SwiftUI

struct EpisodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: EpisodeDetailsViewModel
    let listTitle: String

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    artwork
                    episodeDetails
                        .offset(y: geo.size.width * -0.6)
                        .padding(.bottom, geo.size.width * -0.6)
                    Divider()
                    episodeActions
                }
            }
            .navigationTitle(listTitle)
        }
        .actionSheet(item: $viewModel.actionRequiresConfirmation) { action in
            ActionSheet(title: Text(action.confirmationTitle),
                        message: Text(action.confirmationMessage),
                        buttons: [
                            .cancel(),
                            .destructive(Text(action.confirmationButtonTitle), action: {
                                WKInterfaceDevice.current().play(.click)
                                viewModel.handleEpisodeAction(action, wasConfirmed: true, dismiss: dismissView)
                            })
                        ])
        }
    }

    private var artwork: some View {
        ZStack {
            CachedImage(url: viewModel.episode.largeImageUrl)
            Image("episodegradient", bundle: Bundle.watchAssets)
                .resizable()
        }
    }

    private var episodeDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            playPauseButton
            Text(viewModel.episode.title ?? "")
                .font(.dynamic(size: 15, weight: .medium))

            Text(viewModel.episode.subTitle())
                .foregroundColor(viewModel.episode.subTitleColor)
                .font(.dynamic(size: 12, weight: .medium))
            Text(viewModel.episode.displayDate)
                .foregroundColor(.subheadlineText)
                .font(.dynamic(size: 12))
            Text(viewModel.episode.displayableInfo())
                .foregroundColor(.subheadlineText)
                .font(.dynamic(size: 12, weight: .medium))

            if !viewModel.episode.episodeDetails.isEmpty {
                Text(viewModel.episode.episodeDetails)
                    .font(.dynamic(size: 13, weight: .medium))
            }
        }
    }

    private var playPauseButton: some View {
        Button {
            WKInterfaceDevice.current().play(viewModel.isPlaying ? .click : .start)
            viewModel.playPauseTapped()
        } label: {
            Image(viewModel.isPlaying ? "episodepause" : "episodeplay", bundle: Bundle.watchAssets)
        }
        .accessibilityLabel(viewModel.isPlaying ? L10n.pause : L10n.play)
        .buttonStyle(.plain)
    }

    private var episodeActions: some View {
        Group {
            ForEach(viewModel.actions) { action in
                Button(action: {
                    WKInterfaceDevice.current().play(.success)
                    viewModel.handleEpisodeAction(action, dismiss: dismissView)
                }) {
                    switch action {
                    case .pauseDownload:
                        DownloadProgressEpisodeActionView(downloadProgress: $viewModel.downloadProgress)
                    case .playNext, .playLast:
                        UpNextEpisodeActionView(isCurrentlyPlaying: $viewModel.isCurrentlyPlaying, episodeAction: action)
                    default:
                        EpisodeActionView(iconName: action.iconName, title: action.title)
                    }
                }
            }

            if viewModel.supportsPodcastNavigation, let podcast = viewModel.parentPodcast {
                NavigationLink(destination: PodcastEpisodeListView(viewModel: .init(podcast: podcast))) {
                    EpisodeActionView(iconName: "episode_goto", title: L10n.goToPodcast)
                }
            }
        }
    }

    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct EpisodeView_Previews: PreviewProvider {
    static let testViewModel = EpisodeDetailsViewModel(episode: Episode())
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices, id: \.rawValue) { device in
            EpisodeView(viewModel: testViewModel, listTitle: "Test")
                .previewDevice(device)
        }
    }
}
