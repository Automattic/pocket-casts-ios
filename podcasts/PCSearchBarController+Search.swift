import Foundation
import PocketCastsUtils

extension PCSearchBarController {
    func resetSearchTimer() {
        cancelSearchTimer()

        searchTimer = Timer.scheduledTimer(timeInterval: searchDebounce, target: self, selector: #selector(searchTimerFired), userInfo: nil, repeats: false)
    }

    func cancelSearchTimer() {
        if let timer = searchTimer {
            timer.invalidate()

            searchTimer = nil
        }
    }

    @objc private func searchTimerFired() {
        searchTimer = nil

        guard let searchTerm = searchTextField.text?.trim() else { return }
        if FeatureFlag.searchImprovements.enabled {
            if searchTerm.isEmpty { return }
        } else {
            let characterCount = searchTerm.count
            if characterCount < 2 { return }

            let lowerCaseSearch = searchTerm.lowercased()

            // don't auto search for feed URLs
            if (characterCount == 2 && lowerCaseSearch.startsWith(string: "ht")) || (characterCount == 3 && lowerCaseSearch.startsWith(string: "htt")) || lowerCaseSearch.startsWith(string: "http") { return }
        }
        search(searchTerm: searchTerm, triggerdByTimer: true)
    }

    func search(searchTerm: String, triggerdByTimer: Bool) {
        searchIcon.isHidden = true
        loadingSpinner.startAnimating()
        searchDelegate?.performSearch(searchTerm: searchTerm, triggeredByTimer: triggerdByTimer, completion: {
            self.loadingSpinner.stopAnimating()
            self.searchIcon.isHidden = false
        })
    }
}
