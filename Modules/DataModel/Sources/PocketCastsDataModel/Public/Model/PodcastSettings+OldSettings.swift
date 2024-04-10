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
            addToUpNext = newValue.enabled
            if let position = newValue.position {
                addToUpNextPosition = position
            }
        }
    }
}

public extension AutoAddToUpNextSetting {
    var enabled: Bool {
        get {
            return self != .off
        }
    }

    var position: UpNextPosition? {
        switch self {
        case .addFirst:
            return .top
        case .addLast:
            return .bottom
        case .off:
            return nil
        }
    }
}
