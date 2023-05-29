import SwiftUI
import UIKit

/// Allows for applying view modifiers to a SwiftUI View while also passing it into
/// the hosting controller without needing to use AnyView
///
/// Usage: See ThemedHostingController
class ModifedHostingController<Content: View, Modifier: ViewModifier>: UIHostingController<ModifedHostingController.Wrapper> where Content: View {
    init(rootView: Content, modifier: Modifier) {
        super.init(rootView: .init(content: rootView, modifier: modifier))
    }

    struct Wrapper: View {
        let content: Content
        let modifier: Modifier

        var body: some View {
            content.modifier(modifier)
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows easy use of SwiftUI Views by setting the Theme environment object on them
/// Usage of this is:
/// class MyCoolController: ThemedHostingController<MyThemedView> {
///     init(customValue: String) {
///         super.init(rootView: MyThemedView())
///         or if you alread have a theme...
///         super.init(rootView: MyThemedView(), theme: theme)
///     }
/// }
class ThemedHostingController<Content>: ModifedHostingController<Content, ThemedEnvironment> where Content: View {

    init(rootView: Content, theme: Theme = Theme.sharedTheme) {
        super.init(rootView: rootView, modifier: ThemedEnvironment(theme: theme))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PCHostingController<Content>: ThemedHostingController<Content> where Content: View {
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

struct ThemedEnvironment: ViewModifier {
    let theme: Theme
    func body(content: Content) -> some View {
        content.environmentObject(theme)
    }
}

extension View {
    func setupDefaultEnvironment(theme: Theme = Theme.sharedTheme) -> some View {
        self.modifier(ThemedEnvironment(theme: theme))
    }
}
