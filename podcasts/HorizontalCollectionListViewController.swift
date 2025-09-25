import UIKit
import PocketCastsServer

class HorizontalCollectionListViewController: ThemedHostingController<HorizontalCollectionList>, DiscoverSummaryProtocol {

    let model: HorizontalCollectionModel

    init() {
        model = HorizontalCollectionModel()
        super.init(rootView: HorizontalCollectionList(model: model))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
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
