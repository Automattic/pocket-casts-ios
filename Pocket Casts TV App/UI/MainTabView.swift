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

    var body: some View {
        switch tab {
        case .podcasts:
            PodcastsView()
        default:
            if let title = tab.title {
                CenterButton(title: title)
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

    @State private var selection: MainTab = .home
    @FocusState private var focusedArea: FocusArea?

    enum FocusArea: Hashable {
        case tabBar
        case profile
        case content
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selection) {
                ForEach(MainTab.allCases) { tab in
                    Tab(value: tab) {
                        MainTabContentView(tab: tab)
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
            rightAccessory
        }.overlay(alignment: .topLeading) {
            leftAccessory
        }.onAppear {
            focusedArea = .tabBar
        }
        // Intercept right-swipe from tab bar to profile
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .ignoresSafeArea()
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        switch (focusedArea, direction) {
        case (.tabBar, .right):
            // Only jump to profile if we're on the rightmost tab
            if selection == MainTab.allCases.last {
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
        .padding(.top, 50)
        .padding(.trailing, 84)
        .focusSection()
    }

    var leftAccessory: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 40)
            HStack {
                Spacer().frame(width: 84)
                Image(ImageResource.pcLogo)
                Spacer()
            }.frame(height: 78)
            Spacer()
        }
    }
}

#Preview {
    MainTabView()
}
