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
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    var body: some View {
        ZStack {
            if let firstEpisode = episodes.first {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            Rectangle()
                                .fill(colorScheme.topBackgroundColor)
                                .lightBackgroundShadow()
                                .frame(width: .infinity, height: .infinity)
                                .backwardWidgetAccentable(isAccentedRenderingMode)
                                .opacity(isAccentedRenderingMode ? 0.1 : 1)
                            HStack(alignment: .top) {
                                EpisodeView(episode: firstEpisode, topText: isPlaying ? Text(L10n.nowPlaying.localizedCapitalized) : Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: firstEpisode.duration))), isPlaying: isPlaying, isFirstEpisode: true)
                                Spacer()
                                Image(colorScheme.iconAssetName)
                                    .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                                    .frame(width: CommonWidgetHelper.iconSize, height: CommonWidgetHelper.iconSize)
                                    .unredacted()
                            }
                            .padding(16)
                        }
                        .frame(height: geometry.size.height * 82 / 345)

                        ZStack {
                            if !isAccentedRenderingMode {
                                Rectangle()
                                    .fill(colorScheme.bottomBackgroundColor)
                            }

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
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    var body: some View {
        guard episodes.first != nil else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                if showsWidgetBackground, !isAccentedRenderingMode {
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
                                .backwardWidgetAccentable(isAccentedRenderingMode)
                        }
                        Spacer()
                        Image(colorScheme.filterViewIconAssetName)
                            .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                            .frame(width: CommonWidgetHelper.iconSize, height: CommonWidgetHelper.iconSize)
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
                        HStack {
                            Spacer()
                            HungryForMoreView()
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .clearBackground()
            }
        )
    }
}
