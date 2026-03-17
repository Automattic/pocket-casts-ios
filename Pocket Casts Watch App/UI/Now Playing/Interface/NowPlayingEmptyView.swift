import SwiftUI

struct NowPlayingEmptyView: View {
    var body: some View {
        VStack(spacing: 5) {
            Text(L10n.watchNothingPlayingTitle)
                .font(.dynamic(size: 16, weight: .medium))

            Text(L10n.watchNothingPlayingSubtitle)
                .font(.dynamic(size: 14))
                .multilineTextAlignment(.center)
        }
    }
}

struct NowPlayingEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingEmptyView()
    }
}
