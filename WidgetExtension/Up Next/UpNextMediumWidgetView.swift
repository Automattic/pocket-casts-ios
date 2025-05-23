import Foundation
import SwiftUI

struct UpNextMediumWidgetView: View {
    @State var episodes: [WidgetEpisode]
    @State var filterName: String?
    @State var isPlaying: Bool

    var body: some View {
        if let firstEpisode = episodes.first {
            if let topFilter = filterName {
                MediumFilterView(firstEpisode: firstEpisode, secondEpisode: episodes[safe: 1], filterName: topFilter)
            } else {
                MediumUpNextView(firstEpisode: firstEpisode, secondEpisode: episodes[safe: 1], isPlaying: isPlaying)
            }
        } else {
            HungryForMoreView()
        }
    }
}

struct MediumUpNextView: View {
    var firstEpisode: WidgetEpisode
    var secondEpisode: WidgetEpisode?
    var isPlaying: Bool
    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    private var iconAssetName: String {
        isAccentedRenderingMode ? PCWidgetColorScheme.boldNowPlaying.iconAssetName : colorScheme.iconAssetName
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(colorScheme.topBackgroundColor)
                        .lightBackgroundShadow()
                        .backwardWidgetAccentable(isAccentedRenderingMode)
                        .opacity(isAccentedRenderingMode ? 0.1 : 1)
                    HStack(alignment: .top) {
                        EpisodeView(episode: firstEpisode, topText: isPlaying ? Text(L10n.nowPlaying) : Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: firstEpisode.duration))), isPlaying: isPlaying, isFirstEpisode: true)
                        Spacer()
                        Image(iconAssetName)
                            .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                            .frame(width: CommonWidgetHelper.iconSize, height: CommonWidgetHelper.iconSize)
                            .accessibility(hidden: true)
                            .unredacted()
                    }
                    .padding(16)
                    .frame(height: geometry.size.height / 2)
                }

                HStack {
                    if let nextEpisode = secondEpisode {
                        EpisodeView(episode: nextEpisode, topText: Text(CommonWidgetHelper.durationString(duration: nextEpisode.duration)))
                            .padding(16.0)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                        HungryForMoreView()
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height / 2)
                .background(colorScheme.bottomBackgroundColor.opacity(isAccentedRenderingMode ? 0.0 : 1))
            }
        }
    }
}

struct MediumFilterView: View {
    var firstEpisode: WidgetEpisode
    var secondEpisode: WidgetEpisode?
    var filterName: String

    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.showsWidgetContainerBackground) var showsWidgetBackground
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    private let logoHeight: CGFloat = 28

    var body: some View {
        ZStack {
            if showsWidgetBackground, !isAccentedRenderingMode {
                Rectangle().fill(colorScheme.filterViewBackgroundColor)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(filterName)
                        .font(.callout)
                        .fontWeight(.regular)
                        .foregroundColor(colorScheme.filterViewTextColor)
                        .frame(height: 18)
                        .backwardWidgetAccentable(isAccentedRenderingMode)
                    Spacer()
                    Image(colorScheme.filterViewIconAssetName)
                        .backwardWidgetAccentedRenderingMode(isAccentedRenderingMode)
                        .frame(width: CommonWidgetHelper.iconSize, height: CommonWidgetHelper.iconSize)
                        .unredacted()
                }
                .frame(height: 32)

                VStack(alignment: .leading, spacing: 10) {
                    EpisodeView.createCompactWhenNecessaryView(episode: firstEpisode)
                        .frame(minHeight: 42, maxHeight: 56)
                    if let secondEpisode = secondEpisode {
                        EpisodeView.createCompactWhenNecessaryView(episode: secondEpisode)
                            .frame(minHeight: 42, maxHeight: 56)
                    } else {
                        Spacer()
                            .frame(minHeight: 42, maxHeight: 56)
                    }
                }
            }
            .padding(16)
            .clearBackground()
        }
    }
}
