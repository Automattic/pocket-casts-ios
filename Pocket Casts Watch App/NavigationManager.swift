import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import WatchKit

class NavigationManager {
    static let shared = NavigationManager()

    func navigateToMainMenu() {
        guard let topController = topMostController() else {
            return
        }

        topController.popToRootController()
    }

    func navigateToRestorable(name: String, context: Any?) {
        let interfaceType = WatchInterfaceType(rawValue: name)

        if interfaceType == .nowPlaying {
            navigateToNowPlaying(source: SourceManager.shared.currentSource(), fromLaunchEvent: true)
        } else if let interfaceType = interfaceType {
            navigateTo(interfaceType, context: context)
        }
    }

    func navigateTo(_ type: WatchInterfaceType, context: Any?) {

    }

    private var navigatingToNowPlaying = false
    func navigateToNowPlaying(source: Source, fromLaunchEvent: Bool) {
        if navigatingToNowPlaying { return }
        navigatingToNowPlaying = true

        var topController = topMostController()

        if source != SourceManager.shared.currentSource() {
            SourceManager.shared.setSource(newSource: source)
        }
        topController?.popToRootController()
        topController = topMostController()

        if fromLaunchEvent {
            topController = topMostController()
            navigatingToNowPlaying = false
        }
    }

    private func topMostController() -> WKInterfaceController? {
        let visibleController = WKApplication.shared().visibleInterfaceController ?? WKApplication.shared().rootInterfaceController

        return visibleController
    }
}
