import Foundation
import WidgetKit
import SwiftUI

struct NowPlayingWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground

    let colorScheme: PCWidgetColorScheme

    var body: some View {
        if let playingEpisode = entry.episode {
            ZStack { // overkill to get widget background in simulator. TODO: will revisit this before PR
                Rectangle().fill(colorScheme.topBackgroundColor)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        LargeArtworkView(imageData: playingEpisode.imageData)
                        Spacer()
                        Image(colorScheme.iconAssetName)
                            .frame(width: 28, height: 28)
                            .unredacted()
                    }.padding(topPadding)

                    Text(playingEpisode.episodeTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .layoutPriority(1)
                        .padding(episodeTitlePadding)

                    if #available(iOS 17, *) {
                        Toggle(isOn: entry.isPlaying, intent: PlayEpisodeIntent(episodeUuid: playingEpisode.episodeUuid)) {

                            if entry.isPlaying {
                                Text(L10n.nowPlaying)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme.topBackgroundColor)
                            } else {
                                Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme.topBackgroundColor)
                                    .layoutPriority(1)
                            }
                        }
                        .toggleStyle(WidgetFirstEpisodePlayToggleStyle(colorScheme: colorScheme))
                        .padding(bottomTextPadding)
                    } else {
                        if entry.isPlaying {
                            Text(L10n.nowPlaying)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color.secondary)
                                .padding(bottomTextPadding)
                        } else {
                            Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color.secondary)
                                .padding(bottomTextPadding)
                                .layoutPriority(1)
                        }
                    }
                }
                .widgetURL(URL(string: "pktc://last_opened"))
                .clearBackground()
                .if(!showsWidgetBackground) { view in
                    view
                        .padding(.top)
                        .padding(.bottom)
                }
            }
        }
        else if !showsWidgetBackground {
            nothingPlaying
        } else {
            ZStack {
                Image(CommonWidgetHelper.loadAppIconName())
                    .resizable()
            }
            .widgetURL(URL(string: "pktc://last_opened"))
            .clearBackground()
        }
    }

    private var nothingPlaying: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geometry in
                HStack(alignment: .top) {
                    LargeArtworkView()
                        .opacity(0.5)
                    Spacer()
                    Image("logo-transparent")
                        .frame(width: 28, height: 28)
                }.padding(topPadding)
            }
            Text(L10n.widgetsDiscoverPromptTitle)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(Color.primary)
                .lineLimit(2)
                .frame(height: 38, alignment: .center)
                .layoutPriority(1)
                .padding(episodeTitlePadding)

            Text(L10n.widgetsDiscoverPromptMsg)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(Color.secondary)
                .padding(bottomTextPadding)
                .layoutPriority(1)
        }
        .widgetURL(URL(string: "pktc://discover"))
        .clearBackground()
        .if(!showsWidgetBackground) { view in
            view
                .padding(.top)
                .padding(.bottom)
        }
    }

    private var topPadding: EdgeInsets {
        showsWidgetBackground ? EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16) : EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    private var episodeTitlePadding: EdgeInsets {
        showsWidgetBackground ? EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16) : EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    private var bottomTextPadding: EdgeInsets {
        showsWidgetBackground ? EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16) : EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}

//struct NowPlayingEntryView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: WidgetEpisode(commonItem: CommonUpNextItem.init(episodeUuid: "foo", imageUrl: "", episodeTitle: "foo", podcastName: "foo", podcastColor: "#999999", duration: 400, isPlaying: true)), isPlaying: true), colorScheme: widgetColorSchemeContrast)
//                .previewContext(WidgetPreviewContext(family: .systemSmall))
//                .previewDisplayName("Episode Playing")
//
//            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: WidgetEpisode(commonItem: CommonUpNextItem.init(episodeUuid: "foo", imageUrl: "", episodeTitle: "foo", podcastName: "foo", podcastColor: "#999999", duration: 400, isPlaying: true), colorScheme: widgetColorSchemeContrast), isPlaying: false))
//                .previewContext(WidgetPreviewContext(family: .systemSmall))
//                .previewDisplayName("Episode Paused")
//
//            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: nil, isPlaying: true), colorScheme: widgetColorSchemeContrast)
//                .previewContext(WidgetPreviewContext(family: .systemSmall))
//                .previewDisplayName("Nothing Playing")
//        }
//    }
//}
