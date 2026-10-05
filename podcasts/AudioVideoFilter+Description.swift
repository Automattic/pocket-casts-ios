import PocketCastsDataModel

extension AudioVideoFilter {
    var description: String {
        switch self {
        case .all:
            return L10n.filterValueAll
        case .audioOnly:
            return L10n.filterMediaTypeAudio
        case .videoOnly:
            return L10n.filterMediaTypeVideo
        }
    }
}
