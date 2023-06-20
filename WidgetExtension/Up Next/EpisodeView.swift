import Foundation
import SwiftUI
import AppIntents

struct EpisodeView: View {
    @State var episode: WidgetEpisode
    @State var topText: Text
    @State var isPlaying: Bool = false
    var compactView: Bool {
        typeSize >= .xxLarge
    }

    @Environment(\.dynamicTypeSize) var typeSize

    var body: some View {
        Link(destination: CommonWidgetHelper.urlForEpisodeUuid(uuid: episode.episodeUuid)!) {
            HStack(spacing: 12) {
                Toggle("hi", isOn: isPlaying, intent: PlayEpisodeIntent(episode: EpisodeEntity(id: UUID(uuidString: episode.episodeUuid)!)))
                Button(intent: PlayEpisodeIntent(episode: EpisodeEntity(id: UUID(uuidString: episode.episodeUuid)!))) {
                    SmallArtworkView(imageData: episode.imageData)
                }
                VStack(alignment: .leading) {
                    if !compactView {
                        topText
                            .textCase(.uppercase)
                            .font(.caption2)
                            .foregroundColor(Color.secondary)
                    }
                    Text(episode.episodeTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                        .lineLimit(1)
                    HStack(alignment: .center, spacing: 5) {
                        if compactView {
                            topText
                                .textCase(.uppercase)
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                        Text(episode.podcastName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    static func createCompactWhenNecessaryView(episode: WidgetEpisode) -> some View {
        EpisodeView(episode: episode, topText: Text(CommonWidgetHelper.durationString(duration: episode.duration)))
    }
}
