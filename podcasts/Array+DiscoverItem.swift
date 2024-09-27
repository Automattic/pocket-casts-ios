import PocketCastsServer

extension Array<DiscoverItem> {
    func makeDataSourceSnapshot(region: String, itemFilter: (DiscoverItem) -> Bool) -> NSDiffableDataSourceSnapshot<Int, DiscoverItem> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverItem>()

        let section = 0
        snapshot.appendSections([section])
        let items = filter({ (itemFilter($0)) && $0.regions.contains(region) })
        snapshot.appendItems(items)

        return snapshot
    }
}
