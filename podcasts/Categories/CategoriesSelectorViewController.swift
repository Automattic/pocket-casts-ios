import SwiftUI
import PocketCastsServer
import Combine

class CategoriesSelectorViewController: ThemedHostingController<CategoriesSelectorView>, DiscoverSummaryProtocol {

    class DiscoverItemObservable: ObservableObject {
        @Published public var item: DiscoverItem?
        @Published public var selectedCategory: DiscoverCategory?
        @Published public var region: String?

        lazy var load: (() async -> (categories: [DiscoverCategory], popular: [DiscoverCategory])?) = { [weak self] in
            guard let source = self?.item?.source else { return nil }
            let categories = await DiscoverServerHandler.shared.discoverCategories(source: source)
            let popular = categories.filter {
                guard let id = $0.id else { return false }
                return self?.item?.popular?.contains(id) == true
            }

            return (categories, popular)
        }

        init(load: (() async -> (categories: [DiscoverCategory], popular: [DiscoverCategory])?)? = nil) {
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

    func populateFrom(item: PocketCastsServer.DiscoverItem, region: String?) {
        observable.item = item
        observable.region = region
        view.setNeedsLayout()
    }

    init() {
        let observable = DiscoverItemObservable()
        self.observable = observable

        super.init(rootView: CategoriesSelectorView(discoverItemObservable: observable))
        if #available(iOS 16.0, *) {
            sizingOptions =  [.intrinsicContentSize]
        }
        view.backgroundColor = nil

        observable.$selectedCategory.sink { [weak self] category in
            guard let item = observable.item else { return }
            self?.delegate?.showExpanded(item: item, category: category)
        }.store(in: &cancellables)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 16.0, *) {
        } else {
            self.view.invalidateIntrinsicContentSize()
        }
    }
}
