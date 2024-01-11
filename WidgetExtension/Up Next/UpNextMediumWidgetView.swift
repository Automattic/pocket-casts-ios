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

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Rectangle().fill(colorScheme.topBackgroundColor)
                        .lightBackgroundShadow()
                    HStack(alignment: .top) {
                        EpisodeView(episode: firstEpisode, topText: isPlaying ? Text(L10n.nowPlaying) : Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: firstEpisode.duration))), isPlaying: isPlaying, isFirstEpisode: true)
                        Spacer()
                        Image(colorScheme.iconAssetName)
                            .frame(width: 28, height: 28)
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
                .background(colorScheme.bottomBackgroundColor)
            }
        }
    }
}

struct MediumFilterView: View {
    var firstEpisode: WidgetEpisode
    var secondEpisode: WidgetEpisode?
    var filterName: String

    private let logoHeight: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(filterName)
                        .font(.callout)
                        .fontWeight(.regular)
                        .foregroundColor(Color.secondary)
                        .frame(height: 18)
                    Spacer()
                    Image("logo_red_small")
                        .frame(width: 28, height: 28)
                        .unredacted()
                }
                .frame(height: 32)
                EpisodeView.createCompactWhenNecessaryView(episode: firstEpisode)
                    .frame(minHeight: 40, maxHeight: 56)
                Spacer().frame(minHeight: 8, maxHeight: 10)
                if let secondEpisode = secondEpisode {
                    EpisodeView.createCompactWhenNecessaryView(episode: secondEpisode)
                        .frame(minHeight: 40, maxHeight: 56)
                } else {
                    Spacer()
                        .frame(minHeight: 42, maxHeight: 56)
                }
            }
            .padding(geometry.size.height > 155 ? 16 : 12)
            .clearBackground()
        }
    }
}
