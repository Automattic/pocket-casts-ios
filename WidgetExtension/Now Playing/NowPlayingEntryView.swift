import Foundation
import SwiftUI

struct NowPlayingWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    var body: some View {
        if let playingEpisode = entry.episode {
            VStack(alignment: .leading, spacing: 3) {
                GeometryReader { geometry in
                    HStack(alignment: .top) {
                        if #available(iOS 17, *) {
                            Toggle(isOn: entry.isPlaying, intent: PlayEpisodeIntent(episodeUuid: playingEpisode.episodeUuid)) {
                                LargeArtworkView(imageData: playingEpisode.imageData)
                            }
                            .toggleStyle(WidgetPlayToggleStyle())
                        } else {
                            LargeArtworkView(imageData: playingEpisode.imageData)
                        }
                        Spacer()
                        Image("logo-transparent")
                            .frame(width: 28, height: 28)
                    }.padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .background(
                            VStack {
                                Rectangle()
                                    .fill(Color(UIColor(hex: playingEpisode.podcastColor)).opacity(0.85))
                                    .frame(height: 0.667 * geometry.size.height, alignment: .top)
                                Spacer()
                            })
                }
                Text(playingEpisode.episodeTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                    .lineLimit(2)
                    .frame(height: 38, alignment: .center)
                    .layoutPriority(1)
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                if entry.isPlaying {
                    Text(L10n.nowPlaying.localizedUppercase)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                } else {
                    Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)).localizedUppercase)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                        .layoutPriority(1)
                }
            }
            .widgetURL(URL(string: "pktc://last_opened"))
        } else {
            ZStack {
                Image(CommonWidgetHelper.loadAppIconName())
                    .resizable()
            }
            .widgetURL(URL(string: "pktc://last_opened"))
        }
    }
}
