import Foundation
import PocketCastsDataModel
import PocketCastsServer

/// Whether the user listened this year on this device: at least one episode played past five
/// minutes, the rule Playback 2025 used. The Podcasts sheet and the Profile banner are only for
/// them (``Playback2026/showsEntryPoints(isAvailable:isEligible:)``).
///
/// The check reads the database off the main thread. It runs again after a sync, a sign-in and
/// as the user listens, until it passes, and posts ``didChange`` when it does. Main thread only.
final class Playback2026Eligibility {
    static let shared = Playback2026Eligibility()

    static let didChange = Notification.Name("playback2026EligibilityDidChange")

    /// `false` until a check passes.
    private(set) var isEligible = false

    private let notificationCenter: NotificationCenter
    private let queue: DispatchQueue
    private let check: () -> Bool

    private var observers: [NSObjectProtocol] = []
    private var hasStarted = false
    private var hasChecked = false
    private var isChecking = false
    private var needsAnotherCheck = false
    private var afterFirstCheck: [() -> Void] = []

    init(
        notificationCenter: NotificationCenter = .default,
        queue: DispatchQueue = .global(qos: .utility),
        check: @escaping () -> Bool = { DataManager.shared.isEligibleForEndOfYearStories(in: Playback2026.year) }
    ) {
        self.notificationCenter = notificationCenter
        self.queue = queue
        self.check = check
    }

    deinit {
        stopListening()
    }

    /// Runs the first check, and keeps checking until one passes. Does nothing the second time.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let notifications: [Notification.Name] = [
            ServerNotifications.syncCompleted,
            .userSignedIn,
            Constants.Notifications.playbackPaused,
            Constants.Notifications.playbackEnded,
            Constants.Notifications.playbackTrackChanged
        ]
        observers = notifications.map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.update()
            }
        }
        update()
    }

    /// Runs `body` once the first check is done: at once if it is.
    func whenChecked(_ body: @escaping () -> Void) {
        if hasChecked {
            body()
        } else {
            afterFirstCheck.append(body)
        }
    }

    private func update() {
        guard !isEligible else { return }
        guard !isChecking else {
            needsAnotherCheck = true
            return
        }
        isChecking = true

        queue.async { [weak self, check] in
            let isEligible = check()
            DispatchQueue.main.async {
                self?.finishCheck(isEligible: isEligible)
            }
        }
    }

    private func finishCheck(isEligible: Bool) {
        isChecking = false
        hasChecked = true

        if isEligible {
            self.isEligible = true
            stopListening()
            notificationCenter.post(name: Self.didChange, object: nil)
        } else if needsAnotherCheck {
            needsAnotherCheck = false
            update()
        }

        let waiting = afterFirstCheck
        afterFirstCheck = []
        waiting.forEach { $0() }
    }

    private func stopListening() {
        observers.forEach { notificationCenter.removeObserver($0) }
        observers.removeAll()
    }
}
