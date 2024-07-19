import SwiftUI

struct TrimPlayButton: View {
    @State var isPlaying: Bool

    var body: some View {
        Button(action: {
            isPlaying.toggle()
        }) {
            if !isPlaying {
                Image(systemName: "play.fill")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "pause.fill")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
