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

    var body: some View {
        guard let firstEpisode = episodes.first else {
            return AnyView(EmptyView())
        }

        return AnyView(
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Rectangle().fill(Color.clear)
                            .lightBackgroundShadow()
                            .frame(width: .infinity, height: .infinity)
                        HStack(alignment: .top) {
                            EpisodeView(episode: firstEpisode, topText: isPlaying ? Text(L10n.nowPlaying.localizedUppercase) : Text(L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: firstEpisode.duration)).localizedUppercase))
                            Spacer()
                            Image("logo_red_small")
                                .frame(width: 28, height: 28)
                                .unredacted()
                        }
                    }
                    .padding(16)
                    .frame(height: geometry.size.height * 82 / 345)

                    ZStack {
                        Rectangle().fill(darkBackgroundColor)

                        VStack(alignment: .leading, spacing: 10) {
                            if episodes.count > 1 {
                                ForEach(episodes[1 ... min(4, episodes.count - 1)], id: \.self) { episode in

                                    EpisodeView(episode: episode, topText: Text(CommonWidgetHelper.durationString(duration: episode.duration)))
                                        .frame(height: geometry.size.height * 50 / 345)
                                }
                            }

                            if episodes.count < 5 {
                                if episodes.count > 1 {
                                    if episodes.count != 4 {
                                        Spacer().frame(height: 1)
                                    }
                                    Divider()
                                        .background(Color(UIColor.opaqueSeparator))
                                }
                                if episodes.count != 4 {
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    HungryForMoreView()
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .frame(width: .infinity, height: .infinity, alignment: .center)
                    }
                }
            })
    }
}

struct LargeFilterView: View {
    @Binding var episodes: [WidgetEpisode]
    @Binding var filterName: String?

    var body: some View {
        guard episodes.first != nil else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        if let filterName = filterName {
                            Text(filterName)
                                .font(.callout)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .frame(height: 18)
                        }
                        Spacer()
                        Image("logo_red_small")
                            .frame(width: 28, height: 28)
                            .unredacted()
                    }
                    .frame(height: 32)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(episodes[0 ... min(4, episodes.count - 1)], id: \.self) { episode in
                            HStack {
                                EpisodeView.createCompactWhenNecessaryView(episode: episode)
                                    .frame(minHeight: 42, maxHeight: 56)
                                Spacer()
                            }
                        }
                    }
                }.padding(16)
                    .background(Rectangle().fill(Color.clear)
                        .lightBackgroundShadow())

                if episodes.count < 5 {
                    ZStack {
                        Rectangle()
                            .fill(darkBackgroundColor)
                        HungryForMoreView()
                    }
                }
            }
        )
    }
}
