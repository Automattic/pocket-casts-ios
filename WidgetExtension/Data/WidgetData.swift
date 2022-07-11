import Foundation
import SwiftUI

class WidgetData: ObservableObject {
    static let shared = WidgetData()
    
    @Published var nowPlayingEpisode: WidgetEpisode?
    @Published var isPlaying = false
    @Published var topFilterName: String?
    @Published var upNextEpisodes: [WidgetEpisode]?
    @Published var topFilterEpisodes: [WidgetEpisode]?
    
    func reload() {
        nowPlayingEpisode = CommonWidgetHelper.loadNowPlayingEpisode()
        isPlaying = CommonWidgetHelper.loadPlayingStatus()
        topFilterName = CommonWidgetHelper.loadTopFilterName()
        upNextEpisodes = CommonWidgetHelper.loadNowPlayingEpisodes()
        topFilterEpisodes = CommonWidgetHelper.loadTopFilterEpisodes()
    }
}
