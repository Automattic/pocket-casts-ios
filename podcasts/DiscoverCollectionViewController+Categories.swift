import PocketCastsServer

extension DiscoverCollectionViewController {
    private enum Constants {
        static let popularItemsCount = 5
    }

    /// Reloads discover, keeping the items listed in `exclude`
    /// - Parameters:
    ///   - items: Items to exclude from the reload process. These items will REMAIN in Discover
    ///   - category: The `DiscoverCategory` to add to the layout. This is sort of an artifical `DiscoverLayout`.
    func reload(except items: [DiscoverItem], category: DiscoverCategory?) {
        let newLayout: DiscoverLayout?

        if let category {
            newLayout = modified(layout: discoverLayout, for: category, with: items)
        } else {
            newLayout = discoverLayout
        }

        populateFrom(discoverLayout: newLayout, shouldInclude: {
            ($0.categoryID == category?.id) || items.contains($0)
        })
    }

    private func modified(layout: DiscoverLayout?, for category: DiscoverCategory, with items: [DiscoverItem]) -> DiscoverLayout? {

        let popularID = "category-popular-\(category.id ?? 0)"

        // Only add if we haven't already added
        guard layout?.layout?.contains(where: { $0.id == popularID }) == false else { return layout }

        let source = replaceRegionCode(string: category.source)

        let title: String
        if let name = category.name {
            title = L10n.mostPopularWithName(name)
        } else {
            title = L10n.mostPopular
        }

        let item = DiscoverItem(
            id: popularID,
            title: title,
            type: "podcast_list",
            summaryStyle: "large_list",
            summaryItemCount: Constants.popularItemsCount,
            source: source,
            regions: layout!.regions!.map({ $0.key }),
            categoryID: category.id
        )

        var newLayout = layout
        newLayout?.layout?.insert(item, at: layout?.layout?.startIndex.advanced(by: 1) ?? 0)
        return newLayout
    }
}
