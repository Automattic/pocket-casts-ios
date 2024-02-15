import PocketCastsDataModel

extension PodcastSettings {
    var autoUpNextSetting: AutoAddToUpNextSetting {
        if addToUpNext {
            switch addToUpNextPosition {
            case .top:
                return .addFirst
            case .bottom:
                return .addLast
            }
        } else {
            return .off
        }
    }
}
