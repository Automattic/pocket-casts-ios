import PocketCastsServer
import SwiftUI
import UIKit

/// The screen "Show all" opens from a `lists_list` row: every network in the list, in a grid.
struct DiscoverNetworksGridView: View {

    let networks: [NetworkListSummary]

    let onSelect: (NetworkListSummary) -> Void

    @EnvironmentObject var theme: Theme

    private let inset: CGFloat = 24
    private let minimumCardWidth: CGFloat = 150
    private let columnSpacing: CGFloat = 18
    private let rowSpacing: CGFloat = 24

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumCardWidth), spacing: columnSpacing, alignment: .top)], spacing: rowSpacing) {
                ForEach(networks, id: \.self) { network in
                    Button {
                        onSelect(network)
                    } label: {
                        DiscoverNetworkCard(network: network)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(inset)
        }
        .background(theme.primaryUi02)
        .miniPlayerSafeAreaInset()
    }
}

class DiscoverNetworksGridViewController: ThemedHostingController<DiscoverNetworksGridView> {

    private let item: DiscoverItem

    init(item: DiscoverItem, networks: [NetworkListSummary], onSelect: @escaping (NetworkListSummary) -> Void) {
        self.item = item
        super.init(rootView: DiscoverNetworksGridView(networks: networks, onSelect: onSelect), background: \.primaryUi02)

        title = item.title?.localized.localizedCapitalized
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if item.source != nil && item.isAuthenticated == false {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "podcast-share"), style: .plain, target: self, action: #selector(handleShare))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    @objc private func handleShare() {
        guard let source = item.source, let url = URL(string: source)?.deletingPathExtension() else { return }

        Analytics.track(.discoverListShareTapped)
        present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
    }
}

#if DEBUG

#Preview("Networks grid") {
    NavigationStack {
        DiscoverNetworksGridView(
            networks: DiscoverPreviewData.networkCollection(title: "Networks", count: 12).lists,
            onSelect: { _ in }
        )
        .previewFollowingAppearance()
        .navigationTitle(Text("Networks"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
