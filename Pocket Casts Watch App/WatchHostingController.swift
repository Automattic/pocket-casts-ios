import SwiftUI
import WatchKit

class WatchHostingController: WKHostingController<AnyView>, Restorable {
    private enum ContextKey {
        static let controllerType = "controllerType"
        static let wrappedContext = "wrappedContext"
    }

    static let interfaceName = "WatchHostingController"

    static func wrappedContext(fromControllerType controllerType: WatchInterfaceType, withContext context: Any? = nil) -> [String: Any] {
        var wrappedContext: [String: Any] = [ContextKey.controllerType: controllerType.rawValue]
        if let context = context {
            wrappedContext[ContextKey.wrappedContext] = context
        }

        return wrappedContext
    }

    var controllerType: WatchInterfaceType = .unknown
    var context: Any?

    func restoreName() -> String? {
        switch controllerType {
        case .downloads, .podcasts, .files, .filter, .upnext, .nowPlaying:
            return Self.interfaceName
        default:
            return nil
        }
    }

    func restoreContext() -> [String: Any]? {
        Self.wrappedContext(fromControllerType: controllerType, withContext: context)
    }

    override var body: AnyView {
        controllerType.content(context: context) ?? AnyView(Text("Unknown view"))
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        controllerType = controllerType(fromContext: context)
    }

    override func willActivate() {
        super.willActivate()
        if let name = restoreName() {
            UserDefaults.standard.set(name, forKey: WatchConstants.UserDefaults.lastPage)
            UserDefaults.standard.set(restoreContext(), forKey: WatchConstants.UserDefaults.lastContext)
        }
    }

    private func controllerType(fromContext context: Any?) -> WatchInterfaceType {
        guard let context = context as? [String: Any],
              let controllerRawValue = context[ContextKey.controllerType] as? String,
              let controllerType = WatchInterfaceType(rawValue: controllerRawValue)
        else {
            return .unknown
        }

        self.context = context[ContextKey.wrappedContext]
        return controllerType
    }
}

extension WKInterfaceController {
    func pushController(forType controllerType: WatchInterfaceType, context: Any? = nil) {
        let wrappedContext = WatchHostingController.wrappedContext(fromControllerType: controllerType, withContext: context)
        pushController(withName: WatchHostingController.interfaceName, context: wrappedContext)
    }
}
