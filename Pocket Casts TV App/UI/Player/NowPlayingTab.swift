import SwiftUI

struct NowPlayingTab: View {

    @FocusState private var isFocused: Bool
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    @State private var showTab: Bool = true

    var body: some View {
        ZStack {
            NowPlayingView()
                .focused($isFocused)
        }
        .ignoresSafeArea()
        .onChange(of: isFocused) { _, newValue in
            withAnimation(.default) {
                showTab = !newValue
                tabRouter.isShowingDetail = newValue
            }
        }
        .animation(.easeIn, value: isFocused)
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
        .toolbar(showTab ? .visible : .hidden, for: .tabBar)
    }
}
