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
    static func start(from viewController: UIViewController, source: Playback2026Analytics.Source) {
        guard isAvailable, viewController.presentedViewController == nil else { return }
        viewController.present(Playback2026ViewController(), animated: true)
        Playback2026Analytics.track(.endOfYearStoriesShown, properties: ["source": source.rawValue])
    }

    /// Syncs the listening history of the year and the year before when signed in (so the stats,
    /// and the comparison with last year, include episodes played on other devices; the local
    /// history is used if it fails) and builds the payload from it.
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

        // Both years, before the payload is built: `previousYearSeconds` needs last year's.
        if YearListeningHistory.sync(year) {
            FileLog.shared.addMessage("Playback 2026: synced the listening history for \(year) and \(year - 1)")
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
            Playback2026Analytics.track(.endOfYearModalTapped)
            guard let viewController else { return }
            viewController.dismiss(animated: true) {
                start(from: viewController, source: .modal)
            }
        }
        // Only when the user swipes the sheet away, as in 2025.
        BottomSheetSwiftUIWrapper.present(sheet, autoSize: true, in: viewController) {
            Playback2026Analytics.track(.endOfYearModalDismissed)
        }
    }
}
