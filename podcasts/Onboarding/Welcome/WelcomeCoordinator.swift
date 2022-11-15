import Foundation

class WelcomeCoordinator {
    var navigationController: UINavigationController?
    let displayType: DisplayType
    let sections: [WelcomeSection] = [.importPodcasts, .discover]

    init(navigationController: UINavigationController? = nil, displayType: DisplayType) {
        self.navigationController = navigationController
        self.displayType = displayType
    }

    func sectionTapped(_ section: WelcomeSection) {
        switch section {
        case .importPodcasts:
            print("TODO: Future Task")

        case .discover:
            navigationController?.dismiss(animated: true)
            NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
        }
    }

    func doneTapped() {
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Configuration
    enum DisplayType {
        case plus
        case newAccount
    }

    enum WelcomeSection: Int, Identifiable {
        case importPodcasts
        case discover

        var id: Int { rawValue }
    }
}
