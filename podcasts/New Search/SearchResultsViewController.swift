import Foundation
import SwiftUI

protocol SearchResultsDelegate {
    func clearSearch()
    func performLocalSearch(searchTerm: String)
    func performRemoteSearch(searchTerm: String, completion: (() -> Void))
}

class SearchResultsViewController: OnboardingHostingViewController<AnyView> {
    init() {
        super.init(rootView: AnyView(SearchHistoryView().setupDefaultEnvironment()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
