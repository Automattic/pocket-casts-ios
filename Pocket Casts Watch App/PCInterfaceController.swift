import Foundation
import WatchKit

class PCInterfaceController: WKInterfaceController, Restorable {
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()

        if let name = restoreName() {
            UserDefaults.standard.set(name, forKey: WatchConstants.UserDefaults.lastPage)
            UserDefaults.standard.set(restoreContext(), forKey: WatchConstants.UserDefaults.lastContext)
        }

        addAdditionalObservers()
        handleDataUpdated()
        populateTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidUpdate), name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
    }

    override func didDeactivate() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
        removeAllCustomObservers()
    }

    deinit {
        customObservers.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notifications For Updates

    @objc private func dataDidUpdate() {
        DispatchQueue.main.async {
            self.handleDataUpdated()
        }
    }

    func handleDataUpdated() {}
    func addAdditionalObservers() {}
    func populateTitle() {}

    private var customObservers = [Notification.Name]()

    func addCustomObserver(_ name: Notification.Name, selector: Selector) {
        if containsObserver(name) { return } // we already have this one

        customObservers.append(name)

        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }

    func removeAllCustomObservers() {
        if customObservers.count == 0 { return }

        let notCenter = NotificationCenter.default
        for name in customObservers {
            notCenter.removeObserver(self, name: name, object: nil)
        }
        customObservers.removeAll()
    }

    private func containsObserver(_ name: Notification.Name) -> Bool {
        if customObservers.count == 0 { return false }

        return customObservers.contains(name)
    }

    @objc private func nowPlayingTapped() {
        NavigationManager.shared.navigateToNowPlaying(source: SourceManager.shared.currentSource(), fromLaunchEvent: false)
    }

    @objc private func mainMenuTapped() {
        NavigationManager.shared.navigateToMainMenu()
    }

    // MARK: - Restorable

    func restoreName() -> String? { nil }
    func restoreContext() -> [String: Any]? { nil }
}
