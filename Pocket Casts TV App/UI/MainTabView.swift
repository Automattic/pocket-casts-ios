import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case home = 0
    case podcasts
    case playlists
    case upNext
    case search

    var id: Int { return self.rawValue }

    var title: String? {
        switch self {
        case .home: L10n.tvTabHome
        case .podcasts: L10n.tvTabPodcasts
        case .playlists: L10n.tvTabPlaylists
        case .upNext: L10n.tvTabUpNext
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

    @Binding var scrollOffset: Double

    var body: some View {
        switch tab {
        case .home:
            HomeView()
                .onScrollGeometryChange(for: Double.self) { geometry in
                    geometry.contentInsets.top + geometry.contentOffset.y
                } action: { _, after in
                    self.scrollOffset = after
                }
        case .podcasts:
            PodcastsView()
                .onScrollGeometryChange(for: Double.self) { geometry in
                    geometry.contentInsets.top + geometry.contentOffset.y
                } action: { _, after in
                    self.scrollOffset = after
                }
        case .playlists:
            PlaylistsView()
                .onScrollGeometryChange(for: Double.self) { geometry in
                    geometry.contentInsets.top + geometry.contentOffset.y
                } action: { _, after in
                    self.scrollOffset = after
                }
        case .upNext:
            UpNextView()
                .onScrollGeometryChange(for: Double.self) { geometry in
                    geometry.contentInsets.top + geometry.contentOffset.y
                } action: { _, after in
                    self.scrollOffset = after
                }
        case .search:
            SearchView(viewModel: SearchViewModel())                
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

@MainActor
@Observable
final class MainTabRouter {
    var selectedTab: MainTab = .home
    var isShowingDetail: Bool = false
}

struct MainTabView: View {

    @State private var tabSelection: MainTabRouter = MainTabRouter()
    @FocusState private var focusedArea: FocusArea?
    @State private var scrollOffset: Double = 0

    enum FocusArea: Hashable {
        case tabBar
        case profile
        case content
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $tabSelection.selectedTab) {
                ForEach(MainTab.allCases) { tab in
                    Tab(value: tab) {
                        MainTabContentView(tab: tab, scrollOffset: $scrollOffset)
                            .environment(tabSelection)
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
            .focused($focusedArea, equals: .tabBar)
        }.overlay(alignment: .top) {
            accessoryView
        }
        .defaultFocus($focusedArea, .tabBar)
        // Intercept right-swipe from tab bar to profile
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    var accessoryView: some View {
        if !tabSelection.isShowingDetail {
            VStack() {
                HStack() {
                    leftAccessory
                    Spacer()
                    rightAccessory
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 84)
                .offset(x: 0, y: -scrollOffset)
                Spacer()
            }
        }
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        switch (focusedArea, direction) {
        case (.tabBar, .right):
            // Only jump to profile if we're on the rightmost tab
            if tabSelection.selectedTab == MainTab.allCases.last {
                focusedArea = .profile
            }
        case (.profile, .left):
            focusedArea = .tabBar
        default:
            break
        }
    }

    var rightAccessory: some View {
        Button {

        } label: {
            Image(ImageResource.userPlaceholder)
        }
        .buttonStyle(.card)
        .focused($focusedArea, equals: .profile)
        .focusSection()
    }

    var leftAccessory: some View {
        Image(ImageResource.pcLogo)
    }
}

#Preview {
    MainTabView()
}
