import SwiftUI

struct PodcastResultsView: View {
    var body: some View {
        Text("Hello, World!")
            .navigationBarTitle(Text(L10n.discoverAllPodcasts))
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastResultsView()
    }
}
