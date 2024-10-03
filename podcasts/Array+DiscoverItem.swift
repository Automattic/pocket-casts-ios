import PocketCastsServer

extension Array<DiscoverItem> {
    func makeDataSourceSnapshot(region: String, selectedCategory: DiscoverCategory?, itemFilter: (DiscoverItem) -> Bool) -> NSDiffableDataSourceSnapshot<Int, DiscoverCollectionViewController.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverCollectionViewController.Item>()

        let items = filter({ (itemFilter($0)) && $0.regions.contains(region) })

        let models = items.map { item in
            let selectedCategory = item.cellType() != .categoriesSelector ? selectedCategory : nil
            return DiscoverCollectionViewController.Item.item(DiscoverCellModel(item: item, region: region, selectedCategory: selectedCategory))
        }

        snapshot.appendSections([0])
        snapshot.appendItems(models)

        return snapshot
    }
}
