import SwiftUI

struct NowPlayingPlayerItemViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NowPlayingPlayerItemViewController {
        let vc = NowPlayingPlayerItemViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: NowPlayingPlayerItemViewController, context: Context) {
        uiViewController.willBeAddedToPlayer()
    }
}
