import SwiftUI
import UIKit

class PCHostingController<Content>: UIHostingController<Content> where Content: View {
    override func viewDidLoad() {
        super.viewDidLoad()

        // here we can set appearance traits that only apply to our SwiftUI views, and won't bleed into other parts of the app like .appearance() would
        UITableView.appearance(whenContainedInInstancesOf: [PCHostingController.self]).backgroundColor = .clear
        UICollectionView.appearance(whenContainedInInstancesOf: [PCHostingController.self]).backgroundColor = .clear
        UITextView.appearance(whenContainedInInstancesOf: [PCHostingController.self]).backgroundColor = UIColor.clear

        setupNavBar()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func themeDidChange() {
        setupNavBar()
    }

    private func setupNavBar() {
        configureNavBarFor(theme: Theme.preferredLightTheme(), traits: UITraitCollection(userInterfaceStyle: .light))

        let preferredThemeWhenDark = Settings.shouldFollowSystemTheme() ? Theme.preferredDarkTheme() : Theme.preferredLightTheme()
        configureNavBarFor(theme: preferredThemeWhenDark, traits: UITraitCollection(userInterfaceStyle: .dark))
    }

    private func configureNavBarFor(theme: Theme.ThemeType, traits: UITraitCollection) {
        let titleColor = AppTheme.navBarTitleColor(themeOverride: theme)
        let iconsColor = AppTheme.navBarIconsColor(themeOverride: theme)
        let backgroundColor = ThemeColor.secondaryUi01(for: theme)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: titleColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 31, weight: .bold)
        ]
        appearance.shadowColor = nil

        UINavigationBar.appearance(for: traits, whenContainedInInstancesOf: [PCHostingController.self]).standardAppearance = appearance
        UINavigationBar.appearance(for: traits, whenContainedInInstancesOf: [PCHostingController.self]).compactAppearance = appearance
        UINavigationBar.appearance(for: traits, whenContainedInInstancesOf: [PCHostingController.self]).scrollEdgeAppearance = appearance
        UINavigationBar.appearance(for: traits, whenContainedInInstancesOf: [PCHostingController.self]).tintColor = iconsColor
    }
}

extension View {
    func setupDefaultEnvironment(theme: Theme = Theme.sharedTheme) -> some View {
        self.environmentObject(theme)
    }
}
