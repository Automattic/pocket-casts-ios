import Foundation
import SwiftUI

struct UpNextLargeWidgetView: View {
    @State var episodes: [WidgetEpisode]
    @State var filterName: String?
    @State var isPlaying: Bool

    var body: some View {
        if filterName != nil {
            LargeFilterView(episodes: $episodes, filterName: $filterName)
        } else {
            LargeUpNextWidgetView(episodes: $episodes, isPlaying: $isPlaying)
        }
    }
}

struct LargeUpNextWidgetView: View {
    @Binding var episodes: [WidgetEpisode]
    @Binding var isPlaying: Bool
    @Environment(\.widgetColorScheme) var colorScheme

    var body: some View {
        ZStack {
            if let firstEpisode = episodes.first {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            Rectangle().fill(colorScheme.topBackgroundColor)
                                .lightBackgroundShadow()
                                .frame(width: .infinity, height: .infinity)
                            HStack(alignment: .top) {
                                EpisodeView(episode: firstEpisode, topText: isPlaying ? Text(L10n.nowPlaying.localizedCapitalized) : Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: firstEpisode.duration))), isPlaying: isPlaying, isFirstEpisode: true)
                                Spacer()
                                Image("logo_white_small_transparent")
                                    .frame(width: 28, height: 28)
                                    .unredacted()
                            }
                            .padding(16)
                        }
                        .frame(height: geometry.size.height * 82 / 345)

                        ZStack {
                            Rectangle().fill(colorScheme.bottomBackgroundColor)

                            VStack(alignment: .leading, spacing: 10) {
                                if episodes.count > 1 {
                                    ForEach(episodes[1 ... min(4, episodes.count - 1)], id: \.episodeUuid) { episode in

                                        EpisodeView(episode: episode, topText: Text(CommonWidgetHelper.durationString(duration: episode.duration)))
                                            .frame(height: geometry.size.height * 50 / 345)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                else {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HungryForMoreView()
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                            .frame(width: .infinity, height: .infinity, alignment: .center)
                        }
                    }
                }
                .clearBackground()
            } else {
                EmptyView()
            }
        }
    }
}

struct LargeFilterView: View {
    @Binding var episodes: [WidgetEpisode]
    @Binding var filterName: String?

    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground

    var body: some View {
        guard episodes.first != nil else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                if showsWidgetBackground {
                    Rectangle().fill(colorScheme.filterViewBackgroundColor)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        if let filterName = filterName {
                            Text(filterName)
                                .font(.callout)
                                .fontWeight(.regular)
                                .foregroundColor(colorScheme.filterViewTextColor)
                                .frame(height: 18)
                        }
                        Spacer()
                        Image(colorScheme.filterViewIconAssetName)
                            .frame(width: 28, height: 28)
                            .unredacted()
                    }
                    .frame(height: 32)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(episodes[0 ... min(4, episodes.count - 1)], id: \.self) { episode in
                            HStack {
                                EpisodeView.createCompactWhenNecessaryView(episode: episode)
                                    .frame(minHeight: 42, maxHeight: 56)
                            }
                        }
                    }

                    Spacer()

                    if episodes.count == 1 {
                        HungryForMoreView()
                    }
                }
                .padding(16)
                .clearBackground()
            }
        )
    }
}
