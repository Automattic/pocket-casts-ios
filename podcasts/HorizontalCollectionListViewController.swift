import UIKit
import PocketCastsServer

class HorizontalCollectionListViewController: ThemedHostingController<HorizontalCollectionList>, DiscoverSummaryProtocol {

    init() {
        super.init(rootView: HorizontalCollectionList())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {

    }

    func populateFrom(item: DiscoverItem, region: String?, category: DiscoverCategory?) {

    }

}
