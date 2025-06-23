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

            // Filter categories by popularity
            var filteredCategories = categories.filter {
                guard let id = $0.id else { return false }
                return self.item?.popular?.contains(id) == true
            }

            // Filter and rank categories by recommendations
            if FeatureFlag.smartCategories.enabled,
               let recommendedSource = item?.recommendations?.source,
               let recommendedCategories = await self.serverHandler.discoverRecommendedCategories(source: recommendedSource, authenticated: item?.authenticated) {
                filteredCategories = categories
                    // Filter categories based on recommended IDs
                    .compactMap { category -> DiscoverCategory? in
                        guard let id = category.id, recommendedCategories.contains(id) else { return nil }
                        return category
                    }
                    // Filter categories based on position in recommendedIDs
                    .sorted { lhs, rhs in
                        guard let lhsId = lhs.id, let rhsId = rhs.id,
                              let lhsIndex = recommendedCategories.firstIndex(of: lhsId),
                              let rhsIndex = recommendedCategories.firstIndex(of: rhsId) else {
                            return false
                        }
                        return lhsIndex < rhsIndex
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
