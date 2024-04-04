import SwiftUI
import PocketCastsServer

class CategoriesSelectorViewController: UIHostingController<CategoriesSelectorView> {
    init(item: DiscoverItem) {
        super.init(rootView: CategoriesSelectorView(item: item))
        if #available(iOS 16.0, *) {
            sizingOptions =  [.intrinsicContentSize]
        }
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
