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

struct SourceInterfaceForm: View {

    @StateObject var model = SourceInterfaceModel()

    var body: some View {
        List {
            Section {
                NavigationLink(destination: InterfaceView(source: .phone)) { SourceRow(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone) }
                NavigationLink(destination: InterfaceView(source: .watch)) { SourceRow(sourceSymbol: L10n.watch.sourceUnicode(isWatch: true), label: L10n.watch) }
            } footer: {
                if model.isPlusUser {
                    Text(L10n.watchSourceMsg)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.gray)
                }
            }
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
            Section {
                UserRow(username: model.usernameLabel, profileImage: model.profileImage, isLoggedIn: model.isLoggedIn)
                    .listRowBackground(Color.clear)
            } footer: {
                if !model.isLoggedIn {
                    Text(L10n.watchSourceSignInInfo)
                        .font(.footnote)
                }
            }
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
        }.onAppear {
            model.willActivate()
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
}

#Preview {
    SourceInterfaceForm()
}
