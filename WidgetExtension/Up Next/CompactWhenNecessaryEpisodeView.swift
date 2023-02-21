import SwiftUI

// This class exists to wrap iOS 15 only-logic for using compact EpisodeView when dynamicTypeSize is large enough to cause issues in the widget.
// It can be removed, and the `typeSize` logic can be moved into EpisodeView once iOS 15 is the minimum build version for Pocket Casts.
@available(iOS 15.0, *)
struct CompactWhenNecessaryEpisodeView: View {
    @State var episode: WidgetEpisode
    @State var topText: Text

    @Environment(\.dynamicTypeSize) var typeSize

    var body: some View {
        EpisodeView(episode: episode, topText: topText, compactView: typeSize >= .xxLarge)
    }
}
