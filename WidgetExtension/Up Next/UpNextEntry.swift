import Foundation
import SwiftUI
import WidgetKit

struct UpNextEntry: TimelineEntry {
    @State var date: Date
    @State var episodes: [WidgetEpisode]?
    @State var filterName: String?
    @State var isPlaying: Bool
    @State var upNextEpisodesCount: Int?
}
