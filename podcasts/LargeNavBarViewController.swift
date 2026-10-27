import UIKit

class LargeNavBarViewController: PCViewController {
    func setupLargeTitle() {
        changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        largeTitleFont = UIFont.font(ofSize: 22, weight: .bold, scalingWith: .title2)

        if !LiquidGlass.isEnabled {
            configureLegacyOpaqueNavBarAppearance()
        }
    }

    private func configureLegacyOpaqueNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.setBackIndicatorImage(UIImage(named: "nav-back"), transitionMaskImage: UIImage(named: "nav-back"))
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
    }

    override func handleThemeChanged() {
        setupLargeTitle()
    }
}
