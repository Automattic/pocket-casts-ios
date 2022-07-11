import Foundation
import WidgetKit

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let episode: WidgetEpisode?
    let isPlaying: Bool
}
