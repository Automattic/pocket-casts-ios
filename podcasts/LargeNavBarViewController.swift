import Foundation
class LargeNavBarViewController: PCViewController {
    func setupLargeTitle() {
        changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.sizeToFit()

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

    func closeAction() {}
    @objc func closeTapped(_ sender: Any) {
        closeAction()
        dismiss(animated: true, completion: nil)
    }

    override func handleThemeChanged() {
        setupLargeTitle()
    }

    func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }
}
