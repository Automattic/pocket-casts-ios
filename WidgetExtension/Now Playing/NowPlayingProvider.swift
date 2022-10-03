import Foundation
import WidgetKit

struct NowPlayingProvider: TimelineProvider {
    typealias Entry = NowPlayingEntry

    func placeholder(in context: Context) -> NowPlayingEntry {
        let widgetData = WidgetData.shared
        widgetData.reload()

        return nowPlayingEntry(from: widgetData)
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        let widgetData = WidgetData.shared
        widgetData.reload()

        completion(nowPlayingEntry(from: widgetData))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let widgetData = WidgetData.shared
        widgetData.reload()

        let entry = nowPlayingEntry(from: widgetData)
        let policy: TimelineReloadPolicy = widgetData.nowPlayingEpisode == nil ? .never : .atEnd
        let timeline = Timeline(entries: [entry], policy: policy)

        completion(timeline)
    }

    private func nowPlayingEntry(from widgetData: WidgetData) -> NowPlayingEntry {
        let episode = widgetData.nowPlayingEpisode
        episode?.loadImageData()

        return NowPlayingEntry(date: Date(), episode: episode, isPlaying: widgetData.isPlaying)
    }
}
