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
               let recommendations = UserDefaults.standard.visitations(for: .discoverCategory) {

                let recommendedIDs = recommendations
                    .sorted { $0.value > $1.value }
                    .map { $0.key }

                // Dictionary to speed up lookup and preserve original category objects
                let categoriesByID = Dictionary(uniqueKeysWithValues: categories.compactMap { category -> (String, DiscoverCategory)? in
                    guard let id = category.id else { return nil }
                    return (String(id), category)
                })

                var sortedCategories: [DiscoverCategory] = recommendedIDs.compactMap { categoriesByID[$0] }

                let remainingCategories = filteredCategories.filter { category in
                    guard let id = category.id else { return false }
                    return !recommendedIDs.contains(String(id))
                }

                sortedCategories.append(contentsOf: remainingCategories)
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
