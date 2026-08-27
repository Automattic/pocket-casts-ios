import UIKit
import PocketCastsServer

class HorizontalCollectionListViewController: ThemedHostingController<HorizontalCollectionList>, DiscoverSummaryProtocol {

    let model: HorizontalCollectionModel

    var serverHandler: DiscoverServerHandling {
        get { model.serverHandler }
        set { model.serverHandler = newValue }
    }

    init() {
        model = HorizontalCollectionModel()
        super.init(rootView: HorizontalCollectionList(model: model))
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

#Preview("Collection") {
    let section = HorizontalCollectionListViewController()
    section.serverHandler = PreviewDiscoverServerHandler(
        podcastCollection: DiscoverPreviewData.podcastCollection(
            title: "Sounds for sleeping",
            subtitle: "Staff picks",
            description: "Nine shows for winding down, chosen by the people who make Pocket Casts.",
            shortDescription: "Chosen by the Pocket Casts team",
            podcasts: DiscoverPreviewData.podcasts(9)
        )
    )
    return DiscoverSectionPreview(
        section: section,
        item: DiscoverPreviewData.item(.collectionSummary, title: "Collection")
    )
}

#endif
