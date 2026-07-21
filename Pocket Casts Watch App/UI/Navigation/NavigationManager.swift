import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    /// The app launches showing the current source's interface list.
    @Published var path: [WatchRoute] = [.source(SourceManager.shared.currentSource())]

    func navigateToRestorable(name: String, context: Any?) {
        let interfaceType = WatchInterfaceType(rawValue: name)

        if interfaceType == .nowPlaying {
            navigateToNowPlaying(source: SourceManager.shared.currentSource(), fromLaunchEvent: true)
        } else if let interfaceType {
            navigateTo(interfaceType, context: context)
        }
    }

    /// Replaces the stack with the current source's interface list plus `type`.
    func navigateTo(_ type: WatchInterfaceType, context: Any?) {
        guard let route = WatchRoute(type) else { return }

        path = [.source(SourceManager.shared.currentSource()), route]
    }

    /// Pushes on top of whatever is already on the stack.
    func push(_ type: WatchInterfaceType) {
        guard let route = WatchRoute(type) else { return }

        path.append(route)
    }

    private var navigatingToNowPlaying = false
    func navigateToNowPlaying(source: Source, fromLaunchEvent: Bool) {
        if navigatingToNowPlaying { return }
        navigatingToNowPlaying = true

        if source != SourceManager.shared.currentSource() {
            SourceManager.shared.setSource(newSource: source)
        }
        path = [.source(source), .interface(.nowPlaying)]
        navigatingToNowPlaying = false
    }
}
