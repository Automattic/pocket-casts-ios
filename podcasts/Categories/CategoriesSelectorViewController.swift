import SwiftUI
import PocketCastsServer
import Combine
import PocketCastsUtils

class CategoriesSelectorViewController: ThemedHostingController<CategoriesSelectorView>, DiscoverSummaryProtocol {

    class DiscoverItemObservable: ObservableObject {
        @Published public var item: DiscoverItem?
        @Published public var selectedCategory: DiscoverCategory?
        @Published public var region: String?
        private(set) var cachedCategories = [DiscoverCategory]()

        private let serverHandler: DiscoverServerHandling

        lazy var load: (() async -> (categories: [DiscoverCategory], prioritized: [DiscoverCategory])?) = { [weak self] in
            guard let self, let source = self.item?.source else { return ([], []) }

            let categories = await self.serverHandler.discoverCategories(source: source, authenticated: self.item?.authenticated)

            // Determine which categories to work with
            let workingCategories: [DiscoverCategory]
            if let popular = self.item?.popular {
                workingCategories = categories.filter {
                    guard let id = $0.id else { return false }
                    return popular.contains(id)
                }
            } else {
                workingCategories = categories
            }

            // Filter and rank categories by recommendations
            var filteredCategories = workingCategories
            if FeatureFlag.smartCategories.enabled,
               let recommendations = UserDefaults.standard.visitations(for: .discoverCategory) {

                let categories = item?.sponsoredCategoryIDs
                let sponsoredIDs = Set(item?.sponsoredCategoryIDs?.map { String($0) } ?? [])
                let recommendedIDs = recommendations
                    .sorted { $0.value > $1.value }
                    .map { $0.key }

                // Separate sponsored and non-sponsored categories
                let sponsoredCategories = workingCategories.filter { category in
                    guard let id = category.id.map(String.init) else { return false }
                    return sponsoredIDs.contains(id)
                }

                let nonSponsoredCategories = workingCategories.filter { category in
                    guard let id = category.id.map(String.init) else { return false }
                    return !sponsoredIDs.contains(id)
                }

                var sortedCategories: [DiscoverCategory] = []

                // 1. Add ALL sponsored categories first, sorted by visitation order
                let sponsoredByVisitation = sponsoredCategories.sorted { lhs, rhs in
                    guard let lhsID = lhs.id.map(String.init),
                          let rhsID = rhs.id.map(String.init) else { return false }

                    let lhsIndex = recommendedIDs.firstIndex(of: lhsID)
                    let rhsIndex = recommendedIDs.firstIndex(of: rhsID)

                    switch (lhsIndex, rhsIndex) {
                    case (.some(let l), .some(let r)):
                        return l < r  // Both visited - sort by visit order
                    case (.some, .none):
                        return true   // Visited comes before unvisited
                    case (.none, .some):
                        return false  // Unvisited comes after visited
                    case (.none, .none):
                        return false  // Both unvisited - keep original order
                    }
                }
                sortedCategories.append(contentsOf: sponsoredByVisitation)

                // 2. Add non-sponsored visited categories in visit order
                for recommendedID in recommendedIDs {
                    if let category = nonSponsoredCategories.first(where: { $0.id.map(String.init) == recommendedID }) {
                        sortedCategories.append(category)
                    }
                }

                // 3. Add remaining non-sponsored, non-visited categories in original order
                let addedIDs = Set(sortedCategories.compactMap { $0.id.map(String.init) })
                for category in nonSponsoredCategories {
                    guard let id = category.id.map(String.init) else { continue }
                    if !addedIDs.contains(id) {
                        sortedCategories.append(category)
                    }
                }

                filteredCategories = sortedCategories
            }

            self.cachedCategories = categories
            return (categories, filteredCategories)
        }

        init(serverHandler: DiscoverServerHandling = DiscoverServerHandler.shared,
             load: (() async -> (categories: [DiscoverCategory], prioritized: [DiscoverCategory])?)? = nil) {
            self.serverHandler = serverHandler
            if let load {
                self.load = load
            }
        }
    }
    @ObservedObject fileprivate var observable: DiscoverItemObservable

    private weak var delegate: DiscoverDelegate?

    private var cancellables: Set<AnyCancellable> = []

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        self.delegate = delegate
    }

    func setCategory(_ category: String) {
        for categoryObject in observable.cachedCategories {
            if categoryObject.name?.lowercased() == category {
                observable.selectedCategory = categoryObject
            }
        }
    }

    func populateFrom(item: PocketCastsServer.DiscoverItem, region: String?, category: DiscoverCategory?) {
        observable.item = item
        observable.region = region
        view.setNeedsLayout()
    }

    init() {
        let observable = DiscoverItemObservable()
        self.observable = observable

        super.init(rootView: CategoriesSelectorView(discoverItemObservable: observable))
        sizingOptions =  [.intrinsicContentSize]
        view.backgroundColor = nil

        self.observable.$selectedCategory
            .delay(for: .milliseconds(20), scheduler: DispatchQueue.main)
            .sink { [weak self] category in
                guard let item = self?.observable.item else { return }
                self?.delegate?.showExpanded(item: item, category: category)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.discoverNavigateToCategory)
            .receive(on: OperationQueue.main)
            .sink { [unowned self] notification in
                guard let category = notification.object as? String else {
                    return
                }
                self.setCategory(category)
            }
            .store(in: &cancellables)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
