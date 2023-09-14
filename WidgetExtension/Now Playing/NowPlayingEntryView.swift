import Foundation
import WidgetKit
import SwiftUI

struct NowPlayingWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground

    var body: some View {
        if let playingEpisode = entry.episode {
            VStack(alignment: .leading, spacing: 3) {
                GeometryReader { geometry in
                    HStack(alignment: .top) {
                        if #available(iOS 17, *) {
                            Toggle(isOn: entry.isPlaying, intent: PlayEpisodeIntent(episodeUuid: playingEpisode.episodeUuid)) {
                                LargeArtworkView(imageData: playingEpisode.imageData, showShadow: showsWidgetBackground)
                            }
                            .toggleStyle(WidgetPlayToggleStyle())
                        } else {
                            LargeArtworkView(imageData: playingEpisode.imageData)
                        }
                        Spacer()
                        Image("logo-transparent")
                            .frame(width: 28, height: 28)
                    }.padding(topPadding)
                        .background(
                            VStack {
                                if showsWidgetBackground {
                                    Rectangle()
                                        .fill(Color(UIColor(hex: playingEpisode.podcastColor)).opacity(0.85))
                                        .frame(height: 0.667 * geometry.size.height, alignment: .top)
                                }
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
                    .padding(episodeTitlePadding)

                if entry.isPlaying {
                    Text(L10n.nowPlaying.localizedUppercase)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary)
                        .padding(bottomTextPadding)
                } else {
                    Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)).localizedUppercase)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary)
                        .padding(bottomTextPadding)
                        .layoutPriority(1)
                }
            }
            .widgetURL(URL(string: "pktc://last_opened"))
            .clearBackground()
            .if(!showsWidgetBackground) { view in
                view
                    .padding(.top)
                    .padding(.bottom)
            }
        } else if !showsWidgetBackground {
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

struct NowPlayingEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: WidgetEpisode(commonItem: CommonUpNextItem.init(episodeUuid: "foo", imageUrl: "", episodeTitle: "foo", podcastName: "foo", podcastColor: "#999999", duration: 400, isPlaying: true)), isPlaying: true))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Episode Playing")

            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: nil, isPlaying: true))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Nothing Playing")
        }
    }
}
