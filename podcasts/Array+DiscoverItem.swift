import PocketCastsServer

extension Array<DiscoverItem> {
    func makeDataSourceSnapshot(region: String, selectedCategory: DiscoverCategory?, itemFilter: (DiscoverItem) -> Bool) -> NSDiffableDataSourceSnapshot<Int, DiscoverCellType.ItemType> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverCellType.ItemType>()

        let items = filter({ (itemFilter($0)) && $0.regions.contains(region) })

        let models = items.map { item in
            let selectedCategory = item.cellType() != .categoriesSelector ? selectedCategory : nil
            return DiscoverCellModel(item: item, region: region, selectedCategory: selectedCategory)
        }

        snapshot.appendSections([0])
        snapshot.appendItems(models)

        return snapshot
    }
}
