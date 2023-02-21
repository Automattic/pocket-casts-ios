import Foundation
import SwiftUI

protocol SearchResultsDelegate {
    func clearSearch()
    func performLocalSearch(searchTerm: String)
    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void))
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

class SearchResultsViewController: OnboardingHostingViewController<AnyView> {
    init() {
        super.init(rootView: AnyView(SearchHistoryView().setupDefaultEnvironment()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchResultsViewController: SearchResultsDelegate {
    func clearSearch() {
        print("clear search")
    }

    func performLocalSearch(searchTerm: String) {
        print("local search: \(searchTerm)")
    }

    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void)) {
        print("remote search: \(searchTerm)")
    }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {

    }
}
