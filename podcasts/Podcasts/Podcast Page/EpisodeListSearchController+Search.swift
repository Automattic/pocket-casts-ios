import Foundation

extension EpisodeListSearchController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        podcastDelegate?.didActivateSearch()
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchTerm = textField.text, searchTerm.count > 0 {
            textField.resignFirstResponder()
            cancelSearchTimer()
            search(searchTerm: searchTerm)
        }

        return true
    }

    func handleTextFieldDidChange() {
        let searchTerm = searchTextField.text

        if let searchTerm = searchTerm, searchTerm.count > 0 {
            clearSearchBtn.isHidden = false
            resetSearchTimer()
        } else {
            cancelSearch()
        }
    }

    @IBAction func clearSearchTapped(_ sender: Any) {
        cancelSearch()
    }

    private func cancelSearch() {
        searching = false

        searchTextField.text = ""
        clearSearchBtn.isHidden = true
        cancelSearchTimer()

        podcastDelegate?.clearSearch()
    }

    func resetSearchTimer() {
        cancelSearchTimer()

        searchTimer = Timer.scheduledTimer(timeInterval: Settings.episodeSearchDebounceTime(), target: self, selector: #selector(searchTimerFired), userInfo: nil, repeats: false)
    }

    func cancelSearchTimer() {
        if let timer = searchTimer {
            timer.invalidate()

            searchTimer = nil
        }
    }

    @objc private func searchTimerFired() {
        searchTimer = nil

        guard let searchTerm = searchTextField.text else { return }

        let characterCount = searchTerm.count
        if characterCount < 2 { return }

        search(searchTerm: searchTerm)
    }

    func handleSearchCompleted() {
        loadingSpinner.stopAnimating()
        searchIcon.isHidden = false
    }

    private func search(searchTerm: String) {
        performSearch()
    }

    private func performSearch() {
        let searchQuery = searchTextField?.text ?? ""

        // don't allow searching for less than 2 characters
        if searchQuery.count < 2 { return }

        searching = true
        searchIcon.isHidden = true
        loadingSpinner.startAnimating()
        print("Searching for \(searchQuery)")
        podcastDelegate?.searchEpisodes(query: searchQuery)
    }
}
