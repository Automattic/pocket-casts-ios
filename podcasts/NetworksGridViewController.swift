import SwiftUI
import UIKit

/// "Show All" for a `lists_list` item: every network in the collection, laid out as a grid.
class NetworksGridViewController: PCHostingController<NetworksGrid> {

    init(model: NetworksListModel) {
        super.init(rootView: NetworksGrid(model: model), background: \.primaryUi02)
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct NetworksGrid: View {

    @ObservedObject var model: NetworksListModel

    @EnvironmentObject var theme: Theme

    private let spacing: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let cardSize = (geometry.size.width - (spacing * 3)) / 2
            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(cardSize), spacing: spacing), GridItem(.fixed(cardSize))], spacing: spacing) {
                    ForEach(Array(model.networks.enumerated()), id: \.offset) { _, network in
                        Button {
                            model.show(network: network)
                        } label: {
                            NetworkPoster(network: network, size: cardSize)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(spacing)
            }
            .scrollIndicators(.hidden)
        }
        .background(theme.primaryUi02)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: Constants.effectiveMiniPlayerOffset)
        }
    }
}
