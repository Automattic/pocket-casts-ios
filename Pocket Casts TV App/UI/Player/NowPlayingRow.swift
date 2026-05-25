import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel

struct NowPlayingRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct NowPlayingRow: View {

    let model: EpisodeRowViewModel
    @State var showPlayer: Bool = false

    @Environment(\.isFocused) private var isFocused: Bool

    init(model: EpisodeRowViewModel) {
        self.model = model
    }

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
        Button {
            model.play()
            showPlayer.toggle()
        } label: {
            HStack(spacing: 48) {
                thumbnail
                    .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading) {
                    Spacer()
                    Text(model.displayDate)
                        .font(.body)
                        .foregroundColor(isFocused ? .textSecondaryActive : .textSecondary)
                    Text(model.episode.displayableTitle())
                        .font(.title3)
                        .foregroundColor(isFocused ? .textPrimaryActive : .textPrimary)
                        .lineLimit(2)
                    ProgressView(value: model.playedUpTo, total: model.duration)
                        .foregroundStyle(.blue)
                        .tint(model.currentPodcastTintColor)
                        .clipShape(RoundedRectangle(cornerRadius: 100))
                    Text(model.timeLeft)
                        .font(.body)
                        .foregroundColor(isFocused ? .textSecondaryActive : .textSecondary)
                    Spacer()
                }
                Spacer()
            }
            .padding(32)
            .background(isFocused ? Color.backgroundActive : Color.backgroundSunken)
        }
        .buttonStyle(.card)
        .fullScreenCover(isPresented: $showPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }
}


#Preview {
    NowPlayingRow(model: EpisodeRowViewModel(episode: MockData.makeStubEpisodes().first!, podcast: MockData.makeStubPodcasts().first!))
    .environment(AppCoordinator())
    .environment(MainTabRouter())
}
