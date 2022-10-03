import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import WatchKit

class NavigationManager {
    static let shared = NavigationManager()

    func navigateToMainMenu() {
        var topController = topMostController()
        if topController is InterfaceController { return }

        topController?.popToRootController()
        topController = topMostController()

        topController?.pushController(withName: InterfaceController.controllerRestoreName, context: nil)
    }

    func navigateToRestorable(name: String, context: Any?) {
        let interfaceType = WatchInterfaceType(rawValue: name)

        if interfaceType == .nowPlaying {
            navigateToNowPlaying(source: SourceManager.shared.currentSource(), fromLaunchEvent: true)
        } else if let interfaceType = interfaceType {
            navigateTo(interfaceType, context: context)
        } else {
            var topController = topMostController()

            if (topController as? PCInterfaceController)?.restoreName() != InterfaceController.controllerRestoreName {
                topController?.popToRootController()
                topController = topMostController()

                topController?.pushController(withName: InterfaceController.controllerRestoreName, context: nil)
                topController = topMostController()
            }

            if name != InterfaceController.controllerRestoreName {
                topController?.pushController(withName: name, context: context)
            }
        }
    }

    func navigateTo(_ type: WatchInterfaceType, context: Any?) {
        var topController = topMostController()

        if (topController as? PCInterfaceController)?.restoreName() != InterfaceController.controllerRestoreName {
            topController?.popToRootController()
            topController = topMostController()

            topController?.pushController(withName: InterfaceController.controllerRestoreName, context: nil)
            topController = topMostController()
        }

        topController?.pushController(forType: type, context: context)
    }

    private var navigatingToNowPlaying = false
    func navigateToNowPlaying(source: Source, fromLaunchEvent: Bool) {
        if navigatingToNowPlaying { return }
        navigatingToNowPlaying = true

        var topController = topMostController()
        if let topController = topController as? WatchHostingController,
           topController.controllerType == .nowPlaying,
           source == SourceManager.shared.currentSource() {
            navigatingToNowPlaying = false
            return
        }

        if source != SourceManager.shared.currentSource() {
            SourceManager.shared.setSource(newSource: source)
        }
        topController?.popToRootController()
        topController = topMostController()

        topController?.pushController(withName: InterfaceController.controllerRestoreName, context: nil)

        if fromLaunchEvent {
            // watchOS seems to have issues with pushing one controller on top of another during a launch event. Since the APIs are so limited, there appears to be no better way to fix this than to wait for the first one to appear
            // where does 0.8 come from? It's a bit arbitrary but a 300ms animation time + load time. Any longer and it's enough time for the user to tap things as well.
            SwiftUtils.performAfterDelayOnMainThread(0.8) {
                topController = self.topMostController()

                topController?.pushController(forType: .nowPlaying)
                self.navigatingToNowPlaying = false
            }
        } else {
            topController = topMostController()
            topController?.pushController(forType: .nowPlaying)
            navigatingToNowPlaying = false
        }
    }

    private func topMostController() -> WKInterfaceController? {
        let visibleController = WKExtension.shared().visibleInterfaceController ?? WKExtension.shared().rootInterfaceController

        return visibleController
    }
}
