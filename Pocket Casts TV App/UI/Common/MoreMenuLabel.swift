import SwiftUI

/// Standard "More" (overflow) affordance for section headers on tvOS: an
/// ellipsis that opens a `Menu` of secondary options such as sorting. Pair it
/// with `.buttonStyle(MoreButtonStyle())` so it renders as the same perfect
/// circle used by the per-row ellipsis in `EpisodeRowWithActions`.
struct MoreMenuLabel: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .accessibilityLabel(L10n.tvMoreMenu)
    }
}

#Preview {
    Menu {
        Button("Newest to oldest") {}
        Button("Oldest to newest") {}
    } label: {
        MoreMenuLabel()
    }
    .buttonStyle(MoreButtonStyle())
}
