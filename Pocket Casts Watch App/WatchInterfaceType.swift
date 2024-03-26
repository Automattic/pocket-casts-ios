import Foundation
import PocketCastsDataModel
import SwiftUI

enum WatchInterfaceType: String {
    case unknown
    case effects
    case episodeDetails
    case downloads
    case podcasts
    case files
    case filter
    case upnext
    case nowPlaying
    case filterList
    case interface
}

extension WatchInterfaceType {
    func content(context: Any?) -> AnyView? {
        switch self {
        case .downloads:
            return AnyView(DownloadListView())
        case .podcasts:
            return AnyView(PodcastsListView())
        case .files:
            return AnyView(FilesListView())
        case .filter:
            guard let filterView = FilterEpisodeListView(context: context) else { return nil }
            return AnyView(filterView)
        case .upnext:
            return AnyView(UpNextView())
        case .nowPlaying:
            return AnyView(NowPlayingContainerView())
        case .filterList:
            return AnyView(FiltersListView())
        case .interface:
            return AnyView(InterfaceView(source: .phone))
        default:
            return nil
        }
    }
}
