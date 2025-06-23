import PocketCastsServer

extension Array<DiscoverItem> {
    func makeDataSourceSnapshot(region: String, selectedCategory: DiscoverCategory?, itemFilter: (DiscoverItem) -> Bool) -> NSDiffableDataSourceSnapshot<Int, DiscoverCollectionViewController.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverCollectionViewController.Item>()

        let items = filter({ (itemFilter($0)) })

        let models: [DiscoverCollectionViewController.Item] = items.compactMap { item in
            let selectedCategory = item.cellType() != .categoriesSelector ? selectedCategory : nil
            let model = DiscoverCellModel(item: item, region: region, selectedCategory: selectedCategory)
            guard let cellType = item.cellType() else { return nil }
            return DiscoverCollectionViewController.Item.item(DiscoverCellType.ItemType(cellType: cellType, model: model))
        }

        snapshot.appendSections([0])
        snapshot.appendItems(models)

        return snapshot
    }
}
