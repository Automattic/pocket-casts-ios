import UIKit
import PocketCastsServer
import PocketCastsUtils

enum Playback2026 {
    /// The single check every entry point (Podcasts sheet, Profile banner) and the story flow use.
    static var isAvailable: Bool {
        FeatureFlag.playback2026.enabled
    }

    // MARK: - Entry points

    static let year = 2026

    private static var isStarting = false

    static func start(from viewController: UIViewController) {
        guard isAvailable, !isStarting else { return }
        isStarting = true

        Task { @MainActor [weak viewController] in
            defer { isStarting = false }

            let payload = await Task.detached(priority: .userInitiated) {
                syncListeningHistoryIfNeeded()
                return Playback2026Payload.make(year: year)
            }.value

            guard let viewController else { return }

            do {
                let playbackViewController = try Playback2026ViewController(payload: payload)
                viewController.present(playbackViewController, animated: true)
            } catch {
                FileLog.shared.addMessage("Playback 2026: failed to start: \(error)")
            }
        }
    }

    nonisolated private static func syncListeningHistoryIfNeeded() {
        guard SyncManager.isUserLoggedIn() else { return }

        let hasSubscription = SubscriptionHelper.hasActiveSubscription()
        guard !Settings.hasSyncedEpisodesForPlayback(year: year) || Settings.hasSyncedEpisodesForPlaybackAsPlusUser(year: year) != hasSubscription else { return }

        if YearListeningHistory.sync(year) {
            Settings.setHasSyncedEpisodesForPlayback(true, year: year)
            Settings.setHasSyncedEpisodesForPlaybackAsPlusUser(hasSubscription, year: year)
        } else {
            FileLog.shared.addMessage("Playback 2026: listening history sync failed, using local data")
        }
    }

    // MARK: - Podcasts sheet

    private static let hasShownSheetKey = "playback2026SheetHasBeenShown"

    static var hasShownSheet: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownSheetKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownSheetKey) }
    }

    static func shouldShowSheet(isAvailable: Bool = Playback2026.isAvailable, hasShownSheet: Bool = Playback2026.hasShownSheet) -> Bool {
        isAvailable && !hasShownSheet
    }

    static func showSheetIfNeeded(in viewController: UIViewController) {
        guard shouldShowSheet(), viewController.presentedViewController == nil else {
            return
        }

        let sheet = Playback2026Sheet { [weak viewController] in
            guard let viewController else { return }
            viewController.dismiss(animated: true) {
                start(from: viewController)
            }
        }
        BottomSheetSwiftUIWrapper.present(sheet, autoSize: true, in: viewController)
    }
}
