import SwiftUI
import PocketCastsServer

class CategoriesSelectorViewController: UIHostingController<CategoriesSelectorView>, DiscoverSummaryProtocol {

    class Observable: ObservableObject {
        @Published public var item: DiscoverItem?
    }

    @ObservedObject fileprivate var observable: Observable

    func registerDiscoverDelegate(_ delegate: any DiscoverDelegate) {}

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
