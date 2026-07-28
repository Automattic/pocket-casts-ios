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

        guard let searchTerm = searchTextField.text?.trim(), !searchTerm.isEmpty else { return }

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
