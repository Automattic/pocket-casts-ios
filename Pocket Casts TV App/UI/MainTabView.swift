import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable, Equatable {
    case home = 0
    case podcasts
    case playlists
    case upNext
    case nowPlaying
    case search

    var id: Int { return self.rawValue }

    var title: String? {
        switch self {
        case .home: L10n.tvTabHome
        case .podcasts: L10n.tvTabPodcasts
        case .playlists: L10n.tvTabPlaylists
        case .upNext: L10n.tvTabUpNext
        case .nowPlaying: L10n.tvTabNowPlaying
        case .search: nil
        }
    }

    var icon: String? {
        switch self {
        case .search: "magnifyingglass"
        default: nil
        }
    }
}

struct MainTabContentView: View {
    let tab: MainTab

    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    var body: some View {
        ZStack {
            switch tab {
            case .home:
                HomeView()
                    .onScrollGeometryChange(for: Double.self) { geometry in
                        geometry.contentInsets.top + geometry.contentOffset.y
                    } action: { _, after in
                        tabRouter.scrollOffset = after
                    }
            case .podcasts:
                PodcastsView()
                    .onScrollGeometryChange(for: Double.self) { geometry in
                        geometry.contentInsets.top + geometry.contentOffset.y
                    } action: { _, after in
                        tabRouter.scrollOffset = after
                    }
            case .playlists:
                PlaylistsView()
                    .onScrollGeometryChange(for: Double.self) { geometry in
                        geometry.contentInsets.top + geometry.contentOffset.y
                    } action: { _, after in
                        tabRouter.scrollOffset = after
                    }
            case .upNext:
                UpNextView()
                    .onScrollGeometryChange(for: Double.self) { geometry in
                        geometry.contentInsets.top + geometry.contentOffset.y
                    } action: { _, after in
                        tabRouter.scrollOffset = after
                    }
            case .search:
                SearchView(model: SearchViewModel())                    
            case .nowPlaying:
                NowPlayingTab()
            }
        }
    }
}

struct CenterButton: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Button(title) {
            }
            Spacer()
        }
    }
}

struct MainTabView: View {
    @Namespace var mainTabFocusNS

    @State private var tabRouter = MainTabRouter()
    @FocusState private var focusedArea: FocusArea?
    @FocusState private var profileFocused: Bool
    @Environment(AppCoordinator.self) var coordinator

    enum FocusArea: Hashable {
        case tabBar
        case profile
        case content
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $tabRouter.selectedTab) {
                ForEach(MainTab.allCases) { tab in
                    if tabRouter.shouldShowTab(tab) {
                        Tab(value: tab) {
                            MainTabContentView(tab: tab)
                                .environment(tabRouter)
                                .focused($focusedArea, equals: .content)
                        } label: {
                            Label {
                                if let title = tab.title { Text(title) }
                            } icon: {
                                if let icon = tab.icon { Image(systemName: icon) }
                            }
                        }
                    }
                }
            }
            .focused($focusedArea, equals: .tabBar)
        }.overlay(alignment: .top) {
            accessoryView
        }
        .defaultFocus($focusedArea, .tabBar)
        .focusScope(mainTabFocusNS)
        .if(tabRouter.selectedTab == .home) { content in
            content.onMoveCommand { direction in
                handleMove(direction)
            }
        }
        .ignoresSafeArea()
        .background(Color.pcBackgroundSurface)
        .requireAccountSupport()
    }

    @ViewBuilder
    var accessoryView: some View {
        if !tabRouter.isShowingDetail {
            VStack() {
                HStack() {
                    profileAccessory
                    Spacer()
                    logoAccessory
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 84)
                .offset(x: 0, y: -tabRouter.scrollOffset)
                Spacer()
            }
        }
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        switch (focusedArea, direction) {
        case (.tabBar, .left):
            // Dispatch async so the tab selection binding has time to settle
            // after the focus engine handles the move — otherwise rapid lefts
            // from Podcasts → Home → (try profile) read a stale selectedTab.
            DispatchQueue.main.async {
                if tabRouter.selectedTab == MainTab.allCases.first {
                    focusedArea = .profile
                }
            }
        case (.profile, .right):
            focusedArea = .tabBar
        default:
            break
        }
    }

    @State private var showProfileMenu: Bool = false

    var profileAccessory: some View {
        Button {
            showProfileMenu = true
        } label: {
            Group {
                if let email = coordinator.userState.usernameEmail {
                    ProfileImage(email: email)
                } else {
                    Image(ImageResource.profileTab)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                }
            }
            .frame(width: 64, height: 64)
            .background(Color.pcTextPrimary.opacity(0.15), in: Circle())
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.pcTextPrimary, lineWidth: profileFocused ? 4 : 0)
            )
        }
        .buttonStyle(ChromelessButtonStyle())
        .focusEffectDisabled()
        .focused($focusedArea, equals: .profile)
        .focused($profileFocused)
        .scaleEffect(profileFocused ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: profileFocused)
        .focusSection()
        .accessibilityLabel(L10n.tvProfileButtonAccessibilityLabel)
        .accessibilityHint(L10n.tvProfileButtonAccessibilityHint)
        .sheet(isPresented: $showProfileMenu) {
            ProfileMenuView(onAuthSelected: { destination in
                tabRouter.pendingAuthFlow = destination
                showProfileMenu = false
            }, onProfileSelected: { destination in
                tabRouter.profileDestination = destination
                showProfileMenu = false
            })
            .environment(coordinator)
        }
        .fullScreenCover(item: $tabRouter.profileDestination) { destination in
            ZStack {
                Color.pcBackgroundSurface.ignoresSafeArea()
                switch destination {
                case .starred:
                    StarredEpisodesView()
                case .history:
                    ListeningHistoryView()
                }
            }
            .environment(coordinator)
            .environment(tabRouter)
            .onExitCommand {
                tabRouter.profileDestination = nil
            }
        }
        .fullScreenCover(item: $tabRouter.pendingAuthFlow) { destination in
            ZStack {
                Color.pcBackgroundSurface.ignoresSafeArea()
                NavigationStack {
                    Group {
                        switch destination {
                        case .signIn:
                            SignInView()
                        case .createAccount:
                            CreateAccountView(style: .fullScreen)
                        }
                    }
                    .navigationDestination(for: WelcomeView.Destination.self) { destination in
                        ZStack {
                            Color.pcBackgroundSurface
                                .ignoresSafeArea()
                            switch destination {
                            case .signIn:
                                SignInView()
                            case .createAccount:
                                CreateAccountView(style: .fullScreen)
                            }
                        }
                    }
                }
            }
            .environment(coordinator)
            .onExitCommand {
                tabRouter.pendingAuthFlow = nil
            }
        }
    }

    var logoAccessory: some View {
        Image(ImageResource.pcLogo)
    }
}

/// Custom button style that renders only the label, with no platform chrome
/// (no background, lift, or pressed-state overlay).
struct ChromelessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
}
