import SwiftUI

struct NowPlayingTab: View {

    @FocusState private var isFocused: Bool
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    var body: some View {
        ZStack {
            NowPlayingView()
                .focused($isFocused)
                .toolbar(!isFocused ? .automatic : .hidden, for: .tabBar)
        }
        .ignoresSafeArea()        
        .onAppear {
            //This is to force the player to load the current episode
            if !PlaybackManager.shared.playing() {
                DispatchQueue.main.async {
                    PlaybackManager.shared.play(completion: {
                        DispatchQueue.main.async {
                            PlaybackManager.shared.pause()
                        }
                    }, userInitiated: false)
                }
            }
        }
    }
}
