import UIKit
import PlaybackKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

enum Playback2026 {
    /// The feature flag, which the story flow checks. The Podcasts sheet and the Profile banner
    /// also need ``isEligible``.
    static var isAvailable: Bool {
        FeatureFlag.playback2026.enabled
    }

    // MARK: - Entry points

    static let year = 2026

    /// The feature name, which isn't translated.
    static let name = "Playback 2026"

    /// Whether the user played an episode past five minutes this year on this device, the rule
    /// Playback 2025 used. `false` until ``checkEligibility()`` finds it, then it stays `true`.
    private(set) static var isEligible = false

    /// Reads the database off the main thread when the user isn't eligible yet.
    @MainActor
    static func checkEligibility() async -> Bool {
        guard isAvailable else { return false }
        if !isEligible, await Task.detached(priority: .utility, operation: { DataManager.shared.isEligibleForEndOfYearStories(in: year) }).value {
            isEligible = true
        }
        return isEligible
    }

    /// Opens the stories at once. The listening history is read while the intro plays
    /// (``Playback2026ViewController``); if the user moves on before it is there, the intro shows
    /// a spinner until it is.
    ///
    /// Signed out, it opens the sign-in flow instead, as Playback 2025 did, and the stories open
    /// once that flow is closed signed in (``startAfterSignInIfNeeded(from:)``).
    static func start(from viewController: UIViewController, source: Playback2026Analytics.Source) {
        guard isAvailable, viewController.presentedViewController == nil else { return }

        if !SyncManager.isUserLoggedIn() {
            isWaitingForSignIn = true
            let controller = OnboardingFlow.shared.begin(flow: .endOfYear, source: .endOfYear, traitCollection: viewController.traitCollection)
            viewController.present(controller, animated: true)
            return
        }

        viewController.present(Playback2026ViewController(), animated: true)
        Playback2026Analytics.track(.endOfYearStoriesShown, properties: ["source": source.rawValue])
    }

    private static var isWaitingForSignIn = false

    /// Opens the stories when the sign-in flow that ``start(from:source:)`` opened is closed
    /// signed in. Returns whether it did.
    static func startAfterSignInIfNeeded(from viewController: UIViewController) -> Bool {
        guard isWaitingForSignIn else { return false }
        isWaitingForSignIn = false
        guard SyncManager.isUserLoggedIn() else { return false }
        start(from: viewController, source: .userLogin)
        return true
    }

    /// Syncs the listening history of the year and the year before when signed in (so the stats,
    /// and the comparison with last year, include episodes played on other devices; the local
    /// history is used if it fails) and builds the payload from it, with the listener archetype
    /// the server works out, asked for meanwhile. Opened again while the sync runs, it waits for
    /// that sync instead of starting another.
    nonisolated static func makePayload() async -> PlaybackPayload {
        let archetype = Task { await fetchArchetype() }
        await historySync.run()
        let fetchedArchetype = await archetype.value
        return await Task.detached(priority: .userInitiated) {
            Playback2026Payload.make(year: year, archetype: fetchedArchetype)
        }.value
    }

    nonisolated private static let historySync = Playback2026HistorySync { syncListeningHistoryIfNeeded() }

    /// `nil` when the server can't be reached: the stories show their default archetype.
    nonisolated private static func fetchArchetype() async -> Playback2026Archetype? {
        guard SyncManager.isUserLoggedIn() else { return nil }
        do {
            let archetype = try await Playback2026ArchetypeTask().archetype()
            FileLog.shared.addMessage("Playback 2026: archetype \(archetype.rawValue)")
            return archetype
        } catch {
            FileLog.shared.addMessage("Playback 2026: couldn't get the archetype, the stories show their default: \(error)")
            return nil
        }
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

    static func shouldShowSheet(isAvailable: Bool = Playback2026.isAvailable, isEligible: Bool = Playback2026.isEligible, hasShownSheet: Bool = Playback2026.hasShownSheet) -> Bool {
        isAvailable && isEligible && !hasShownSheet
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
