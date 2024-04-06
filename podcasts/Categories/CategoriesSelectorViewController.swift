import SwiftUI
import PocketCastsServer
import Combine

class CategoriesSelectorViewController: UIHostingController<CategoriesSelectorView>, DiscoverSummaryProtocol {

    class Observable: ObservableObject {
        @Published public var item: DiscoverItem?
        @Published public var selectedCategory: DiscoverCategory?
    }

    @ObservedObject fileprivate var observable: Observable

    private weak var delegate: DiscoverDelegate?

    private var cancellables: Set<AnyCancellable> = []

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: PocketCastsServer.DiscoverItem) {
        observable.item = item
        view.setNeedsLayout()
    }

    init() {
        let observable = Observable()
        self.observable = observable

        super.init(rootView: CategoriesSelectorView(observable: observable))
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
