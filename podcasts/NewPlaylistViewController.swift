import UIKit
import SwiftUI

class NewPlaylistViewController: PCViewController {
    weak var delegate: FilterCreatedDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        setupContent()
        addCloseButton()
    }

    private func setupNavBar() {
        title = L10n.playlistsEmptyStateButton

        navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.sizeToFit()
    }
    
    private func setupContent() {
        view.backgroundColor = AppTheme.viewBackgroundColor()
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    private func createManualPlaylist() {

    }
    
    private func createSmartPlaylist() {
        
    }

    @objc private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
