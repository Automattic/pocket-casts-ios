import Foundation

protocol ToastCoordinator: AnyObject {
    /// Called after the toast has been visibly dismissed.
    func toastDismissed()
}

class ToastViewModel: ObservableObject {
    weak var coordinator: ToastCoordinator?

    private var frame: CGRect? = nil
    private var autoDismissTimer: Timer? = nil

    let title: String
    let actions: [Toast.Action]
    let dismissTime: TimeInterval

    deinit {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }

    /// When this is true the view should animate out and call `didDismiss`
    @Published var didAutoDismiss = false

    init(coordinator: ToastCoordinator, title: String, actions: [Toast.Action]?, dismissTime: TimeInterval) {
        self.coordinator = coordinator
        self.title = title
        self.actions = actions ?? []
        self.dismissTime = dismissTime
    }

    // MARK: - Window Methods

    // Inform the window whether the touch point is within the toast view or not
    func hitTest(_ point: CGPoint) -> Bool {
        frame?.contains(point) ?? false
    }

    // MARK: - View Methods

    /// Update the content frame
    func updateFrame(_ frame: CGRect) {
        self.frame = frame
    }

    func didAppear() {
        // Start the auto dismiss timer
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: dismissTime, repeats: false, block: { [weak self] _ in
            self?.handleAutoDismiss()
        })
    }

    // If the toast is already being dismiss, then cancel the timer
    func willDismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil

        // Reset the frame to prevent the hit testing from triggering on an invisible view
        frame = nil
    }

    // Once the toast is fully dismissed, inform the coordinator to do cleanup
    func didDismiss() {
        coordinator?.toastDismissed()
    }

    private func handleAutoDismiss() {
        // Reset timer/frame
        willDismiss()

        // Inform the view we're dismissing now
        didAutoDismiss = true
    }
}
