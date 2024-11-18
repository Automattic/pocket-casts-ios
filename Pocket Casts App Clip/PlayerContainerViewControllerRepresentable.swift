import SwiftUI

struct PlayerContainerViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PlayerContainerViewController {
        return PlayerContainerViewController()
    }

    func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
        // Update the controller if needed
    }
}
