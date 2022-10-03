import PocketCastsDataModel
import WatchKit

protocol Filter {
    var uuid: String { get }
    var title: String { get }
    var iconName: String? { get }
}

class WatchFilter: Equatable, Filter {
    var title = ""
    var uuid = ""
    var iconName: String? = ""

    static func == (lhs: WatchFilter, rhs: WatchFilter) -> Bool {
        lhs.title == rhs.title && lhs.uuid == rhs.uuid && lhs.iconName == rhs.iconName
    }
}

extension EpisodeFilter: Filter {
    var title: String {
        playlistName
    }

    var iconName: String? {
        iconImageName()
    }
}
