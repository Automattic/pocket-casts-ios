import SwiftUI
import PlaybackKit
import PocketCastsUtils

/// Hosts the PlaybackKit experience full screen and turns its events into app behavior.
///
/// The story opens before its data is there: the listening history is synced and read while
/// the intro plays, and handed to the page when it is ready. If the user moves on from the
/// intro first, the page shows a spinner until then.
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

    init() {
        controller = PlaybackController()
        super.init(rootView: Content(controller: controller))
        modalPresentationStyle = .fullScreen
        controller.onEvent = { [weak self] event in
            self?.handle(event)
        }
        // Started with the screen, so it runs while the intro plays. Closed before it is done,
        // the payload has nowhere to go.
        Task { [weak self] in
            let payload = await Playback2026.makePayload()
            self?.setPayload(payload)
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

    private func setPayload(_ payload: PlaybackPayload) {
        do {
            try controller.setPayload(payload)
        } catch {
            FileLog.shared.addMessage("Playback 2026: failed to encode the payload: \(error)")
            // Not JSON: the page shows its error state, rather than a spinner that never ends.
            controller.setPayload(Data())
        }
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
