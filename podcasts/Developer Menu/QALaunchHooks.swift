#if DEBUG
import Foundation
import OSLog
import PocketCastsDataModel
import PocketCastsServer

/// Launch hooks for agent-driven QA on simulators, used by `.agents/skills/qa/scripts/launch.sh`.
///
/// They read environment variables, so they only run for a launch that sets them
/// (`SIMCTL_CHILD_PC_QA_FIXTURES=quiet xcrun simctl launch …`):
/// - `PC_QA_EMAIL` and `PC_QA_PASSWORD`: sign in to a test account and wait for the first sync.
/// - `PC_QA_SERVER`: `staging` or `production`, checked against the build before signing in.
/// - `PC_QA_FIXTURES`: comma-separated fixtures, applied in order:
///   - `quiet`: no onboarding, account-creation prompt, What's New, End of Year or review prompts.
///   - `no-tips`: no tips, banners or upsell popovers.
///   - `up-next:<n>`: fill Up Next with the newest episodes of followed podcasts, so it has `n` episodes after the current one.
///   - `clear-up-next`: empty Up Next, including the current episode.
///   - `subscribe:<podcast uuid>`: follow a podcast.
///   - `sign-out`: sign out and delete local data.
///
/// Fixtures that change account data only run when signed out or signed in by these hooks.
/// Progress goes to the unified log (subsystem `au.com.shiftyjelly.podcasts`, category `QA`),
/// ending with `[QA] ready` or `[QA] failed: …`.
enum QALaunchHooks {
    private static let logger = Logger(subsystem: "au.com.shiftyjelly.podcasts", category: "QA")
    private static let managedEmailKey = "QALaunchHooksSignedInEmail"

    static func runIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        let email = environment["PC_QA_EMAIL"].flatMap { $0.isEmpty ? nil : $0 }
        let fixtures = (environment["PC_QA_FIXTURES"] ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard email != nil || !fixtures.isEmpty else {
            return
        }
        Task {
            do {
                if let email {
                    try checkServer(environment["PC_QA_SERVER"])
                    try await signIn(email: email, password: environment["PC_QA_PASSWORD"] ?? "")
                }
                for fixture in fixtures {
                    try await apply(fixture)
                }
                log("ready")
            } catch {
                log("failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Account

    private static func checkServer(_ expected: String?) throws {
        #if STAGING
        let server = "staging"
        #else
        let server = "production"
        #endif
        guard let expected, expected == server else {
            throw Failure("this build talks to \(server), but the account is for \(expected ?? "an unspecified server")")
        }
    }

    private static func signIn(email: String, password: String) async throws {
        if SyncManager.isUserLoggedIn() {
            if ServerSettings.syncingEmail()?.caseInsensitiveCompare(email) == .orderedSame {
                log("already signed in")
                return
            }
            try requireManagedAccount("switching accounts")
            await MainActor.run { SignOutHelper.signout() }
            await deleteLocalData()
        } else if UserDefaults.standard.string(forKey: managedEmailKey) != nil {
            await deleteLocalData()
        }
        log("signing in")
        _ = try await AuthenticationHelper.validateLogin(username: email, password: password)
        UserDefaults.standard.set(ServerSettings.syncingEmail(), forKey: managedEmailKey)
        NotificationCenter.postOnMainThread(notification: .userSignedIn)
        try await waitForSync()
        log("signed in and synced")
    }

    private static func waitForSync() async throws {
        for second in 1...180 {
            if ServerSettings.lastSyncTime != nil {
                return
            }
            if second.isMultiple(of: 45) {
                RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw Failure("the first sync didn't finish in 3 minutes")
    }

    /// Keeps one test account's podcasts and Up Next from merging into the next one on sign-in.
    private static func deleteLocalData() async {
        await MainActor.run { PlaybackManager.shared.endPlayback(saveCurrentEpisode: false) }
        DataManager.shared.deleteAllData()
        DownloadManager.shared.removeAllDownloadedFiles()
        UserDefaults.standard.removeObject(forKey: managedEmailKey)
        log("deleted local data")
    }

    /// Protects accounts these hooks didn't sign in to, such as a developer's own.
    private static func requireManagedAccount(_ action: String) throws {
        guard SyncManager.isUserLoggedIn() else {
            return
        }
        guard let managed = UserDefaults.standard.string(forKey: managedEmailKey),
              ServerSettings.syncingEmail()?.caseInsensitiveCompare(managed) == .orderedSame else {
            throw Failure("\(action) only runs when signed out or signed in by the QA hooks")
        }
    }

    // MARK: Fixtures

    private static func apply(_ fixture: String) async throws {
        let parts = fixture.split(separator: ":", maxSplits: 1).map(String.init)
        let argument = parts.count > 1 ? parts[1] : nil
        switch parts[0] {
        case "quiet":
            quiet()
        case "no-tips":
            noTips()
        case "up-next":
            guard let count = argument.flatMap(Int.init), count > 0 else {
                throw Failure("up-next needs a count, e.g. up-next:5")
            }
            try requireManagedAccount("up-next")
            try await fillUpNext(count: count)
        case "clear-up-next":
            try requireManagedAccount("clear-up-next")
            await MainActor.run { PlaybackManager.shared.endPlayback() }
        case "subscribe":
            guard let uuid = argument, !uuid.isEmpty else {
                throw Failure("subscribe needs a podcast UUID, e.g. subscribe:<uuid>")
            }
            try requireManagedAccount("subscribe")
            try await subscribe(podcastUuid: uuid)
        case "sign-out":
            try requireManagedAccount("sign-out")
            let wasManaged = UserDefaults.standard.string(forKey: managedEmailKey) != nil
            if SyncManager.isUserLoggedIn() {
                await MainActor.run { SignOutHelper.signout() }
            }
            if wasManaged {
                await deleteLocalData()
            }
        default:
            throw Failure("unknown fixture \(fixture)")
        }
        log("applied \(fixture)")
    }

    private static func quiet() {
        Settings.shouldShowInitialOnboardingFlow = false
        Settings.encourageAccountCreationReferenceDate = Date()
        Settings.lastWhatsNewShown = Settings.appVersion().split(separator: ".").prefix(2).joined(separator: ".")
        if let versionCode = WhatsNewHelper.extractWhatsNewInfo()?.versionCode {
            Settings.whatsNewLastAcknowledged = versionCode
        }
        Settings.showWhatsNewDot = false
        for year in EndOfYear.Year.allCases.compactMap(\.year) {
            Settings.setHasShownModalForEndOfYear(true, year: year)
            Settings.setShowBadgeForEndOfYear(false, year: year)
        }
        if Settings.reviewRequestDates().isEmpty {
            Settings.addReviewRequested()
        }
    }

    private static func noTips() {
        InformationalBannerType.allCases.forEach(Settings.dismissBanner(for:))
        Settings.shouldShowReferralsTip = false
        Settings.suggestedFoldersLastUpsellDate = Date()
        Settings.shouldShowPodcastFeeReloadTip = false
        Settings.shouldShowPodcastViewChangesTip = false
        Settings.shouldShowRecentlyPlayedSortingTip = false
        Settings.shouldShowUpNextSortDurationTip = false
        Settings.shouldShowBookmarksPlayerTip = false
        Settings.shouldShowNewFilterTip = false
        Settings.shouldShowNewFilterTipInCreationView = false
        Settings.shouldShowPlaylistsOnboarding = false
    }

    private static func fillUpNext(count: Int) async throws {
        try await MainActor.run {
            let manager = PlaybackManager.shared
            let needed = count + (manager.currentEpisode == nil ? 1 : 0) - manager.queue.upNextCount()
            guard needed > 0 else {
                return
            }
            let candidates = DataManager.shared.findEpisodesWhere(
                customWhere: "podcast_id IN (SELECT id FROM SJPodcast WHERE subscribed = 1) AND wasDeleted = 0 AND archived = 0 ORDER BY publishedDate DESC, addedDate DESC LIMIT ?",
                arguments: [needed + manager.queue.upNextCount() + 1]
            )
            let episodes = Array(candidates.filter { !manager.queue.contains(episodeUuid: $0.uuid) }.prefix(needed))
            guard episodes.count == needed else {
                throw Failure("up-next:\(count) needs \(needed) more episodes from followed podcasts, found \(episodes.count)")
            }
            manager.bulkAdd(episodes)
        }
    }

    private static func subscribe(podcastUuid: String) async throws {
        let success = await withCheckedContinuation { continuation in
            ServerPodcastManager.shared.addFromUuid(podcastUuid: podcastUuid, subscribe: true) { success in
                continuation.resume(returning: success)
            }
        }
        guard success else {
            throw Failure("couldn't follow podcast \(podcastUuid)")
        }
    }

    // MARK: Logging

    private static func log(_ message: String) {
        logger.notice("[QA] \(message, privacy: .public)")
    }

    private struct Failure: LocalizedError {
        let errorDescription: String?

        init(_ message: String) {
            errorDescription = message
        }
    }
}
#endif
