import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import WatchKit

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    @Published var currentInterface: Int?

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
        currentInterface = type.interfacePosition
    }

    private var navigatingToNowPlaying = false
    func navigateToNowPlaying(source: Source, fromLaunchEvent: Bool) {
        if navigatingToNowPlaying { return }
        navigatingToNowPlaying = true

        if source != SourceManager.shared.currentSource() {
            SourceManager.shared.setSource(newSource: source)
        }
        navigateTo(.nowPlaying, context: nil)
        navigatingToNowPlaying = false
    }

    private func topMostController() -> WKInterfaceController? {
        let visibleController = WKApplication.shared().visibleInterfaceController ?? WKApplication.shared().rootInterfaceController

        return visibleController
    }
}
