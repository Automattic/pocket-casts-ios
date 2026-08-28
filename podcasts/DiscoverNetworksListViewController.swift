import PocketCastsServer
import UIKit

class DiscoverNetworksListViewController: ThemedHostingController<DiscoverNetworksListRowView>, DiscoverSummaryProtocol {

    let model: DiscoverNetworksListModel

    var serverHandler: DiscoverServerHandling {
        get { model.serverHandler }
        set { model.serverHandler = newValue }
    }

    init() {
        model = DiscoverNetworksListModel()
        super.init(rootView: DiscoverNetworksListRowView(model: model))
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        model.registerDiscoverDelegate(delegate)
    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {
        model.populateFrom(item: item, region: region, category: category)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let listId = model.item?.uuid {
            let categoryId = model.category?.id.map(String.init)
            AnalyticsHelper.listImpression(listId: listId, category: categoryId)
        }
    }
}

#if DEBUG

import SwiftUI

#Preview("Networks") {
    let section = DiscoverNetworksListViewController()
    section.serverHandler = PreviewDiscoverServerHandler(
        podcastCollection: DiscoverPreviewData.networkCollection(title: "Networks")
    )
    return DiscoverSectionPreview(
        section: section,
        item: DiscoverPreviewData.item(.networksList, title: "Networks")
    )
}

#endif
