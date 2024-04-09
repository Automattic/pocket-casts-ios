import SwiftUI
import PocketCastsServer

class CategoriesSelectorViewController: UIHostingController<CategoriesSelectorView>, DiscoverSummaryProtocol {

    class DiscoverItemObservable: ObservableObject {
        @Published public var item: DiscoverItem?
    }

    @ObservedObject fileprivate var observable: DiscoverItemObservable

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {}

    func populateFrom(item: PocketCastsServer.DiscoverItem) {
        observable.item = item
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
