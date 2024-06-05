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

    var interfacePosition: Int? {
        switch self {
        case .unknown:
            return nil
        case .effects:
            return 0
        case .episodeDetails:
            return 1
        case .downloads:
            return 2
        case .podcasts:
            return 3
        case .files:
            return 4
        case .filter:
            return 5
        case .upnext:
            return 6
        case .nowPlaying:
            return 7
        case .filterList:
            return 8
        case .interface:
            return nil
        }
    }

    var indexPosition: Int {
        let position = interfacePosition ?? -1
        return position
    }
}
