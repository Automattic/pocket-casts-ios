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

                let sponsoredIDs = Set(item?.sponsoredCategoryIDs?.map { String($0) } ?? [])

                // Get top 6 most visited categories by user
                let sortedByVisits = workingCategories.sorted { lhs, rhs in
                    guard let lhsID = lhs.id.map(String.init),
                          let rhsID = rhs.id.map(String.init) else { return false }

                    let lhsVisits = recommendations[lhsID] ?? 0
                    let rhsVisits = recommendations[rhsID] ?? 0
                    return lhsVisits > rhsVisits
                }

                let top6Categories = Array(sortedByVisits.prefix(6))
                let top6IDs = Set(top6Categories.compactMap { $0.id.map(String.init) })

                // Only promote sponsored categories that are in user's top 6
                let promotableSponsored = sponsoredIDs.intersection(top6IDs)

                filteredCategories = top6Categories.sorted { lhs, rhs in
                    guard let lhsID = lhs.id.map(String.init),
                          let rhsID = rhs.id.map(String.init) else { return false }

                    let lhsSponsored = promotableSponsored.contains(lhsID)
                    let rhsSponsored = promotableSponsored.contains(rhsID)

                    // Sponsored categories from top 6 come first
                    if lhsSponsored != rhsSponsored {
                        return lhsSponsored
                    }

                    // Within same sponsorship status, sort by visit count
                    let lhsVisits = recommendations[lhsID] ?? 0
                    let rhsVisits = recommendations[rhsID] ?? 0
                    return lhsVisits > rhsVisits
                }
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
