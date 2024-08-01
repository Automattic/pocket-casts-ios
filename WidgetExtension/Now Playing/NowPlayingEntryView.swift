import Foundation
import WidgetKit
import SwiftUI

struct NowPlayingWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground
    @Environment(\.widgetFamily) var family

    @Environment(\.colorScheme) var colorScheme
    var widgetColorSchemeLight: PCWidgetColorScheme
    var widgetColorSchemeDark: PCWidgetColorScheme
    var widgetColorScheme: PCWidgetColorScheme {
        get {
            colorScheme == .dark ? widgetColorSchemeDark : widgetColorSchemeLight
        }
    }

    var body: some View {
        if let playingEpisode = entry.episode {
            switch family {
            case .systemSmall:
                smallWidget(playingEpisode: playingEpisode)
            default:
                mediumWidget(playingEpisode: playingEpisode)
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

    private func smallWidget(playingEpisode: WidgetEpisode) -> some View {
        ZStack {
            if showsWidgetBackground {
                Rectangle().fill(widgetColorScheme.bottomBackgroundColor)
            }
            VStack(alignment: .leading, spacing: 10) {
                smallArtwork(playingEpisode: playingEpisode)

                episodeTitle(playingEpisode: playingEpisode)

                playToggleOrPlaybackLabel(playingEpisode: playingEpisode)
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

    private func mediumWidget(playingEpisode: WidgetEpisode) -> some View {
        ZStack {
            if showsWidgetBackground {
                Rectangle().fill(widgetColorScheme.bottomBackgroundColor)
            }

            HStack {
                LargeArtworkView(imageData: playingEpisode.imageData, size: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .bottom) {
                        Text("Now Playing")
                            .font(.caption)
                            .textCase(.uppercase)
                            .padding(topPadding)
                            .foregroundColor(widgetColorScheme.bottomTextColor.opacity(0.6))
                        Spacer()
                        Image(widgetColorScheme.iconAssetName)
                            .frame(width: 28, height: 28)
                            .unredacted()
                    }

                    podcastTitle(playingEpisode: playingEpisode)

                    episodeTitle(playingEpisode: playingEpisode)
                    Spacer()
                    playToggleOrPlaybackLabel(playingEpisode: playingEpisode)
                }
                .frame(maxHeight: 128)
            }
            .padding(16)

            .widgetURL(URL(string: "pktc://last_opened"))
            .clearBackground()
            .if(!showsWidgetBackground) { view in
                view
                    .padding(.top)
                    .padding(.bottom)
            }
        }
    }

    private func smallArtwork(playingEpisode: WidgetEpisode) -> some View {
        HStack(alignment: .top) {
            LargeArtworkView(imageData: playingEpisode.imageData)
                .frame(width: 64, height: 64)
            Spacer()
            Image(widgetColorScheme.iconAssetName)
                .frame(width: 28, height: 28)
                .unredacted()
        }
        .padding(topPadding)
    }

    private func podcastTitle(playingEpisode: WidgetEpisode) -> some View {
        Text(playingEpisode.podcastName)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(widgetColorScheme.bottomTextColor)
            .lineLimit(1)
            .frame(height: 12, alignment: .center)
            .layoutPriority(1)
            .padding(episodeTitlePadding)
    }

    private func episodeTitle(playingEpisode: WidgetEpisode) -> some View {
        Text(playingEpisode.episodeTitle)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(widgetColorScheme.bottomTextColor)
            .lineLimit(1)
            .frame(height: 12, alignment: .center)
            .layoutPriority(1)
            .padding(episodeTitlePadding)
    }

    @ViewBuilder
    private func playToggleOrPlaybackLabel(playingEpisode: WidgetEpisode) -> some View {
        if #available(iOS 17, *) {
            Toggle(isOn: entry.isPlaying, intent: PlayEpisodeIntent(episodeUuid: playingEpisode.episodeUuid)) {

                if entry.isPlaying {
                    Text(L10n.nowPlaying)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(widgetColorScheme.topButtonTextColor)
                } else {
                    Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(widgetColorScheme.topButtonTextColor)
                        .layoutPriority(1)
                }
            }
            .toggleStyle(WidgetFirstEpisodePlayToggleStyle(colorScheme: widgetColorScheme))
            .padding(bottomTextPadding)
        } else {
            if entry.isPlaying {
                Text(L10n.nowPlaying)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(widgetColorScheme.bottomTextColor.opacity(0.6))
                    .padding(bottomTextPadding)
            } else {
                Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration)))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(widgetColorScheme.bottomTextColor.opacity(0.6))
                    .padding(bottomTextPadding)
                    .layoutPriority(1)
            }
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
            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: WidgetEpisode(commonItem: CommonUpNextItem.init(episodeUuid: "foo", imageUrl: "", episodeTitle: "foo", podcastName: "foo", podcastColor: "#999999", duration: 400, isPlaying: true)), isPlaying: true), widgetColorSchemeLight: .bold,
                widgetColorSchemeDark: .bold)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Episode Playing")

            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: WidgetEpisode(commonItem: CommonUpNextItem.init(episodeUuid: "foo", imageUrl: "", episodeTitle: "foo", podcastName: "foo", podcastColor: "#999999", duration: 400, isPlaying: true)), isPlaying: false), widgetColorSchemeLight: .bold,
                widgetColorSchemeDark: .bold)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Episode Paused")

            NowPlayingWidgetEntryView(entry: .init(date: Date(), episode: nil, isPlaying: true), widgetColorSchemeLight: .bold,
                widgetColorSchemeDark: .bold)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Nothing Playing")
        }
    }
}
