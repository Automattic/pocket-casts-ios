import Foundation
import SwiftUI

struct ItemListContainer<Content: View>: View {
    let isEmpty: Bool
    let noItemsTitle: String
    let noItemsSubtitle: String?
    let loading: Bool
    let content: Content

    init(isEmpty: Bool, noItemsTitle: String = L10n.watchNoEpisodes, noItemsSubtitle: String? = nil, loading: Bool = false, @ViewBuilder content: () -> Content) {
        self.isEmpty = isEmpty
        self.noItemsTitle = noItemsTitle
        self.noItemsSubtitle = noItemsSubtitle
        self.loading = loading
        self.content = content()
    }

    var body: some View {
        if loading {
            VStack {
                ProgressView()
                    .frame(width: 50, height: 50)
                Text(L10n.loading)
            }
        } else if isEmpty {
            VStack(spacing: 5) {
                Text(noItemsTitle)
                    .font(.dynamic(size: 16, weight: .medium))

                if let noItemsSubtitle = noItemsSubtitle {
                    Text(noItemsSubtitle)
                        .font(.dynamic(size: 14))
                        .multilineTextAlignment(.center)
                }
            }
        } else {
            content
        }
    }
}
