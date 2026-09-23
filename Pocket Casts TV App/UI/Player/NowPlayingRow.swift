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
                .accessibilityHidden(true)
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
                let trackColor = isFocused ? Color.pcTextSecondaryActive : Color.pcTextSecondary
                RoundProgressView(trackColor: trackColor, progress: model.progress)
                Text(model.timeLeft)
                    .font(.body)
                    .foregroundColor(isFocused ? .pcTextSecondaryActive : .pcTextSecondary)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(32)
        .background(isFocused ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusedCardDepth(isFocused: isFocused, cornerRadius: 12, style: .content)
    }
}


#Preview {
    NowPlayingRow(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!, source: .unknown))
    .environment(AppCoordinator())
    .environment(MainTabViewModel())
}
