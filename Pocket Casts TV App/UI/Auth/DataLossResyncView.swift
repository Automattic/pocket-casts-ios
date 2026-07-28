import SwiftUI
import PocketCastsServer

/// Shown when the local database was wiped while the user stayed logged in. Re-fetches
/// everything behind a spinner, then hands off to the main app.
struct DataLossResyncView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var model = DataLossResyncViewModel()

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L10n.tvResyncFetchingEpisodes)
                .font(.headline)
                .foregroundStyle(Color.pcTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pcBackgroundSurface)
        .ignoresSafeArea()
        .task {
            await model.resync()
            coordinator.state = .signedIn
        }
    }
}

@MainActor
final class DataLossResyncViewModel {
    /// Upper bound so a failed or stalled sync never traps the user on the spinner.
    private static let timeout: TimeInterval = 60

    /// Clears the sync watermarks, kicks off a full resync, and returns once it finishes
    /// (success or failure) or the timeout elapses.
    func resync() async {
        // Force a full re-fetch, and pull as if we'd just logged in so the empty local
        // Up Next / history is never pushed up and used to wipe the server's copy.
        SyncManager.clearSyncWatermarksForFullResync()
        SyncManager.syncReason = .login

        await waitForSyncToFinish()
    }

    private func waitForSyncToFinish() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let center = NotificationCenter.default
            var observers: [NSObjectProtocol] = []
            var didFinish = false

            let finish = {
                guard !didFinish else { return }
                didFinish = true
                observers.forEach { center.removeObserver($0) }
                continuation.resume()
            }

            // syncCompleted/syncFailed end the sync chain; podcastRefreshFailed covers a
            // refresh that can't reach the server (which emits no sync notification).
            let names: [Notification.Name] = [
                ServerNotifications.syncCompleted,
                ServerNotifications.syncFailed,
                ServerNotifications.podcastRefreshFailed
            ]
            observers = names.map { name in
                center.addObserver(forName: name, object: nil, queue: .main) { _ in finish() }
            }

            // Safety net so a stalled sync never traps the user on the spinner.
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout) { finish() }

            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        }
    }
}

#Preview {
    DataLossResyncView()
        .environment(AppCoordinator())
}
