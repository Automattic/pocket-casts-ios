import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct NowPlayingRow: View {

    @Bindable var model: EpisodeRowViewModel

    var callback: (() -> ())?

    var body: some View {
        Button {
            model.play()
            callback?()
        } label: {
            NowPlayingRowLabel(model: model)
        }
        .buttonStyle(EpisodeRowButtonStyle())
        .episodeContextMenu(model: model)
    }
}

private struct NowPlayingRowLabel: View {

    @Bindable var model: EpisodeRowViewModel

    @Environment(\.isFocused) private var isFocused: Bool

    enum Layout {
        static let episodeImageSize = CGFloat(272)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let uuid = model.podcastUuid {
            PodcastImage(uuid: uuid, size: .page)
        } else {
            Image(ImageResource.pcLogo)
        }
    }

    var body: some View {
        HStack(spacing: 48) {
            thumbnail
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Spacer()
                Text(model.displayDate)
                    .font(.body)
                    .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                Text(model.episode.displayableTitle())
                    .font(.title3)
                    .foregroundColor(isFocused ? .pcTextPrimaryActive : .pcTextPrimary)
                    .lineLimit(2)
                ProgressView(value: model.progress)
                    .foregroundStyle(.blue)
                    .tint(model.currentPodcastTintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
                Text(model.timeLeft)
                    .font(.body)
                    .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                Spacer()
            }
            Spacer()
        }
        .padding(32)
        .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


#Preview {
    NowPlayingRow(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!))
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
}
