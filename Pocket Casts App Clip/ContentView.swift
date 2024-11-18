import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            NowPlayingPlayerItemViewControllerRepresentable()
        }
        .ignoresSafeArea()
        .onAppear {
//            let episode =
//            PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
        }
    }
}

#Preview {
    ContentView()
}
