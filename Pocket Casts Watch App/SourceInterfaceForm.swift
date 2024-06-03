import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct SourceRow: View {
    let sourceSymbol: String
    let label: String

    var body: some View {
        HStack {
            Text(sourceSymbol)
                .font(.title2)
            VStack {
                Text(label)
                HStack {
                    Image("gold-plus")
                    Image("plus-only")
                }
            }
            Spacer()
            Image("now-playing-small")
        }
    }
}

struct SourceInterfaceForm: View {

    private var refreshTimedActionHelper = TimedActionHelper()
    @State private var lastAppRefreshText: String = L10n.profileLastAppRefresh(L10n.timeFormatNever)

    var body: some View {
        List {
            Section {
                NavigationLink(destination: InterfaceView(source: .phone)) { SourceRow(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone) }
                NavigationLink(destination: InterfaceView(source: .watch)) { SourceRow(sourceSymbol: L10n.watch.sourceUnicode(isWatch: true), label: L10n.watch) }
            } footer: {
                Text(L10n.watchSourceMsg)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.gray)
            }
            Section {
                Button(action: {
                    refreshDataTapped()
                }, label: {
                    MenuRow(label: L10n.watchSourceRefreshData, icon: "retry")
                })
            } footer: {
                Text(lastAppRefreshText)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            Section {
                Button(action: {
                    refreshAccountTapped()
                }, label: {
                    MenuRow(label: L10n.signedOut, icon: "profile-free")
                        .listRowBackground(Color.clear)
                })
            } footer: {
                Text(L10n.watchSourceSignInInfo)
                    .font(.footnote)
            }
            Section {
                MenuRow(label: L10n.watchSourceRefreshAccount, icon: "profile-refresh")
            } footer: {
                VStack {
                    Text(L10n.watchSourceRefreshAccountInfo)
                    Divider()
                    Image("plus-logo")
                    Divider()
                    Text(L10n.watchSourcePlusInfo)
                }
            }
        }
    }

    private func nowPlayingEpisodesMatchOnBothSources() -> Bool {
        let watchCurrentEpisode = PlaybackManager.shared.currentEpisode()
        let phoneCurrentEpisode = WatchDataManager.playingEpisode()
        if watchCurrentEpisode?.uuid == phoneCurrentEpisode?.uuid {
            if watchCurrentEpisode?.playedUpTo == phoneCurrentEpisode?.playedUpTo {
                return true
            }
        }
        return false
    }

    func refreshDataTapped() {
        WKInterfaceDevice.current().play(.success)
        SessionManager.shared.requestData()

        refreshTimedActionHelper.startTimer(for: 5.seconds, action: {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        })

        lastAppRefreshText = L10n.refreshing
    }

    func refreshAccountTapped() {
        WKInterfaceDevice.current().play(.success)
        SyncManager.signout()
        WatchSyncManager.shared.loginAndRefreshIfRequired()
    }

    private func updateLastRefreshDetails() {
        var lastRefreshText = String()
        if !ServerSettings.lastRefreshSucceeded() || !ServerSettings.lastSyncSucceeded() {
            lastRefreshText = !ServerSettings.lastRefreshSucceeded() ? L10n.refreshFailed : L10n.syncFailed
        } else if SyncManager.isFirstSyncInProgress() {
            lastRefreshText = L10n.syncing
        } else if SyncManager.isRefreshInProgress() {
            lastRefreshText = L10n.refreshing
        } else if let lastUpdateTime = ServerSettings.lastRefreshEndTime() {
            lastRefreshText = L10n.refreshPreviousRun(TimeFormatter.shared.appleStyleElapsedString(date: lastUpdateTime))
        } else {
            lastRefreshText = L10n.timeFormatNever
        }

        DispatchQueue.main.async {
            lastAppRefreshText = lastRefreshText
        }
    }
}

#Preview {
    SourceInterfaceForm()
}
