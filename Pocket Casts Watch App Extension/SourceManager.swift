import Foundation

class SourceManager {
    static let shared = SourceManager()

    private let sourceKey = "sourceKey"
    private var selectedSource: Source = .phone

    init() {
        if UserDefaults.standard.object(forKey: sourceKey) != nil {
            selectedSource = Source(rawValue: UserDefaults.standard.integer(forKey: sourceKey)) ?? .phone
        }
    }

    func setSource(newSource: Source) {
        selectedSource = newSource
        UserDefaults.standard.set(selectedSource.rawValue, forKey: sourceKey)
    }

    func isPhone() -> Bool {
        selectedSource == Source.phone
    }

    func isWatch() -> Bool {
        selectedSource == Source.watch
    }

    func currentSource() -> Source {
        selectedSource
    }
}

enum Source: Int, CaseIterable {
    case watch = 0
    case phone = 1
}
