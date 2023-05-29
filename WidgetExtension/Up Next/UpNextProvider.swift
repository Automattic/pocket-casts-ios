import Foundation
import WidgetKit

struct UpNextProvider: TimelineProvider {
    typealias Entry = UpNextEntry

    func placeholder(in context: Context) -> UpNextEntry {
        let widgetData = WidgetData.shared
        widgetData.reload()

        guard let currentEpisode = widgetData.nowPlayingEpisode else {
            return upNextEntry(episodes: nil, data: widgetData)
        }

        return upNextEntry(episodes: [currentEpisode], data: widgetData, imageCountToCache: context.family.imageCount)
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> Void) {
        let widgetData = WidgetData.shared
        widgetData.reload()

        if let episodes = widgetData.upNextEpisodes {
            completion(upNextEntry(episodes: episodes, data: widgetData, imageCountToCache: context.family.imageCount))
        } else {
            completion(upNextEntry(episodes: nil, data: widgetData))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let widgetData = WidgetData.shared
        widgetData.reload()

        if let filterEpisodes = widgetData.topFilterEpisodes, filterEpisodes.count > 0 {
            let entry = upNextEntry(episodes: filterEpisodes, data: widgetData, imageCountToCache: context.family.imageCount)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        } else if let upNextEpisodes = widgetData.upNextEpisodes, upNextEpisodes.count > 0 {
            let entry = upNextEntry(episodes: upNextEpisodes, data: widgetData, imageCountToCache: context.family.imageCount)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        } else {
            let timeline = Timeline(entries: [upNextEntry(episodes: nil, data: widgetData)], policy: .never)
            completion(timeline)
        }
    }

    private func upNextEntry(episodes: [WidgetEpisode]?, data: WidgetData, imageCountToCache: Int = 0) -> UpNextEntry {
        if let episodes = episodes, episodes.count > 0, imageCountToCache > 0 {
            for episode in episodes.prefix(imageCountToCache) {
                episode.loadImageData()
            }
        }

        return UpNextEntry(date: Date(), episodes: episodes, filterName: data.topFilterName, isPlaying: data.isPlaying, upNextEpisodesCount: data.upNextEpisodesCount)
    }
}

private extension WidgetFamily {
    var imageCount: Int {
        switch self {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        case .systemLarge:
            return 5
        default:
            return 5 // we don't support this size, but added to make switch exhaustive
        }
    }
}
