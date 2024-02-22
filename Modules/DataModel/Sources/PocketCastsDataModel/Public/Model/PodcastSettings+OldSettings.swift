extension PodcastSettings {
    public var autoUpNextSetting: AutoAddToUpNextSetting {
        get {
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
        set {
            switch newValue {
            case .addFirst:
                addToUpNext = true
                addToUpNextPosition = .top
            case .addLast:
                addToUpNext = true
                addToUpNextPosition = .bottom
            case .off:
                addToUpNext = false
            }
        }
    }
}
