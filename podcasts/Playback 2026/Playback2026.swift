import UIKit
import PlaybackKit
import PocketCastsServer
import PocketCastsUtils

enum Playback2026 {
    /// The single check every entry point (Podcasts sheet, Profile banner) and the story flow use.
    static var isAvailable: Bool {
        FeatureFlag.playback2026.enabled
    }

    // MARK: - Entry points

    static let year = 2026

    /// Opens the stories at once. The listening history is read while the intro plays
    /// (``Playback2026ViewController``); if the user moves on before it is there, the intro shows
    /// a spinner until it is.
    static func start(from viewController: UIViewController) {
        guard isAvailable, viewController.presentedViewController == nil else { return }
        viewController.present(Playback2026ViewController(), animated: true)
    }

    /// Syncs the year's listening history when signed in (so the stats include episodes played on
    /// other devices; the local history is used if it fails) and builds the payload from it.
    nonisolated static func makePayload() async -> PlaybackPayload {
        await Task.detached(priority: .userInitiated) {
            syncListeningHistoryIfNeeded()
            return Playback2026Payload.make(year: year)
        }.value
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
