import PocketCastsServer
import UIKit

class NetworksListViewController: ThemedHostingController<NetworksListRowView>, DiscoverSummaryProtocol {

    let model: NetworksListModel

    init() {
        model = NetworksListModel()
        super.init(rootView: NetworksListRowView(model: model))
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
