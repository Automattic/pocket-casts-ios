import Foundation

struct WelcomeCoordinator {
    var navigationController: UINavigationController? = nil

    let displayType: DisplayType
    let sections: [WelcomeSection] = [.importPodcasts, .discover]

    func sectionTapped(_ section: WelcomeSection) {
        print(section)
    }

    func doneTapped() {

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
