import SwiftUI

struct NowPlayingTab: View {

    @FocusState private var isFocused: Bool
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    var body: some View {
        NowPlayingView()
            .focused($isFocused)
            .ignoresSafeArea()
            .onChange(of: isFocused) { _, newValue in
                withAnimation(.default) {
                    tabRouter.isShowingDetail = newValue
                }
            }
            .animation(.easeIn, value: isFocused)
            .onAppear {
                Analytics.track(.playerShown)
                //This is to force the player to load the current episode
                if !PlaybackManager.shared.playing(), !PlaybackManager.shared.isReadyToPlay() {
                    PlaybackManager.shared.loadCurrentEpisode()
                }
            }
            .toolbar(!isFocused ? .visible : .hidden, for: .tabBar)
    }
}
