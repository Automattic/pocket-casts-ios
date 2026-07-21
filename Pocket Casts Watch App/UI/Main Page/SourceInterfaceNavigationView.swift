import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct SourceRow: View {
    let sourceSymbol: String
    let label: String
    let showPlusOnly: Bool
    let active: Bool

    var body: some View {
        HStack {
            Text(sourceSymbol)
                .font(.title2)
            VStack {
                Text(label)
                if showPlusOnly {
                    HStack {
                        Image("gold-plus")
                        Image("plus-only")
                    }
                }
            }
            Spacer()
            if active {
                Image("now-playing-small")
            }
        }
    }
}

struct UserRow: View {
    let username: String
    let profileImage: String
    let isLoggedIn: Bool

    var body: some View {
        HStack {
            Image(profileImage)
            VStack(alignment: .leading) {
                if isLoggedIn {
                    Text(L10n.signedInAs)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Text(username)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct SourceInterfaceNavigationView: View {

    @StateObject var model = SourceInterfaceModel()

    @StateObject private var navigationModel = NavigationManager.shared

    @ViewBuilder
    var sourceSection: some View {
        Section {
            NavigationLink(value: WatchRoute.source(.phone)) {
                SourceRow(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone, showPlusOnly: false, active: model.activeSource == .phone)
            }
            NavigationLink(value: WatchRoute.source(.watch)) {
                SourceRow(sourceSymbol: L10n.watch.sourceUnicode(isWatch: true), label: L10n.watch, showPlusOnly: !model.isLoggedIn || !model.isPlusUser, active: model.activeSource == .watch)
            }.disabled(!model.isPlusUser)
        } footer: {
            if model.isPlusUser {
                Text(L10n.watchSourceMsg)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.gray)
            }
        }
    }

    @ViewBuilder
    var dataRefreshSection: some View {
        if model.isPlusUser {
            Section {
                Button(action: {
                    model.refreshDataTapped()
                }, label: {
                    MenuRow(label: L10n.watchSourceRefreshData, icon: "retry")
                })
            } footer: {
                Text(model.lastRefreshLabel)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    var userSection: some View {
        Section {
            UserRow(username: model.usernameLabel, profileImage: model.profileImage, isLoggedIn: model.isLoggedIn)
                .listRowBackground(Color.clear)
        } footer: {
            if !model.isLoggedIn {
                Text(L10n.watchSourceSignInInfo)
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder
    var refreshAccountSection: some View {
        if !model.isLoggedIn {
            Section {
                Button(action: {
                    model.refreshAccountTapped()
                }, label: {
                    MenuRow(label: L10n.watchSourceRefreshAccount, icon: "profile-refresh")
                })
            } footer: {
                if !model.isPlusUser {
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
    }

    var body: some View {
        NavigationStack(path: $navigationModel.path) {
            List {
                sourceSection
                dataRefreshSection
                userSection
                refreshAccountSection
            }.onAppear {
                model.willActivate()
            }
            .navigationDestination(for: WatchRoute.self) { route in
                WatchRouteView(route: route)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.watchPlaySource)
        }
        .onChange(of: navigationModel.path.first) { _, newValue in
            guard case .source(let source)? = newValue else {
                return
            }
            if source == .phone {
                model.phoneTapped()
            } else {
                model.watchTapped()
            }
        }
        .environmentObject(navigationModel)
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
}

#Preview {
    SourceInterfaceNavigationView()
}
