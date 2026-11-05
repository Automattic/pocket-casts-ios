import SwiftUI
import PlaybackKit

/// Hosts the PlaybackKit experience full screen and turns its events into app behavior.
final class Playback2026ViewController: UIHostingController<Playback2026ViewController.Content> {
    struct Content: View {
        let controller: PlaybackController

        var body: some View {
            PlaybackView(controller: controller)
                .ignoresSafeArea()
                .background(Color.black.ignoresSafeArea())
        }
    }

    private let controller: PlaybackController

    init(payload: PlaybackPayload) throws {
        controller = try PlaybackController(payload: payload)
        super.init(rootView: Content(controller: controller))
        modalPresentationStyle = .fullScreen
        controller.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        controller.load()
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }

    private func handle(_ event: PlaybackEvent) {
        switch event {
        case .close:
            dismiss(animated: true)
        case .share:
            share()
        default:
            break
        }
    }

    private func share() {
        Task { @MainActor in
            await controller.setCaptureMode(true)
            let data = await controller.snapshotPNG()
            await controller.setCaptureMode(false)

            guard let data, let image = UIImage(data: data) else { return }
            let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = view
            activityController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0)
            present(activityController, animated: true)
        }
    }
}
