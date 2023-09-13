import Foundation
import SwiftUI

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
                if #available(iOS 17, *) {
                    Toggle(isOn: isPlaying, intent: PlayEpisodeIntent(episodeUuid: episode.episodeUuid)) {
                        SmallArtworkView(imageData: episode.imageData)
                    }
                    .toggleStyle(WidgetPlayToggleStyle())
                } else {
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

struct WidgetPlayToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .truncationMode(.tail)

            Circle()
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
            Group {
                configuration.isOn ?
                Image("icon-pause")
                    .resizable()
                    .foregroundStyle(.black)
                :
                    Image("icon-play")
                    .resizable()
                    .foregroundStyle(.black)
            }
            .frame(width: 24, height: 24)
        }
        .opacity(0.9)
     }
}
