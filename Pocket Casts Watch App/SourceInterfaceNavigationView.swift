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

    @State var activeSource: Int? = SourceManager.shared.currentSource().rawValue

    @StateObject var model = SourceInterfaceModel()

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: InterfaceView(source: .phone), tag: Source.phone.rawValue, selection: $activeSource) {
                        SourceRow(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone, showPlusOnly: false, active: model.activeSource == .phone)
                    }
                    NavigationLink(destination: InterfaceView(source: .watch), tag: Source.watch.rawValue, selection: $activeSource) {
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
            }.onAppear {
                model.willActivate()
            }.onChange(of: activeSource) { newValue in
                guard let newValue, let newSource = Source(rawValue: newValue) else {
                    return
                }
                if newSource == .phone {
                    model.phoneTapped()
                } else {
                    model.watchTapped()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.watchPlaySource)
        }
        .environmentObject(NavigationManager.shared)
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
