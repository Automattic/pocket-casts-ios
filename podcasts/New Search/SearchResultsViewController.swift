import Foundation
import SwiftUI

class SearchResultsViewController: OnboardingHostingViewController<AnyView> {
    init() {
        super.init(rootView: AnyView(SearchHistoryView().setupDefaultEnvironment()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
