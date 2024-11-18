import SwiftUI

struct NowPlayingPlayerItemViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NowPlayingPlayerItemViewController {
        return NowPlayingPlayerItemViewController()
    }

    func updateUIViewController(_ uiViewController: NowPlayingPlayerItemViewController, context: Context) {
        // Update the controller if needed
    }
}
