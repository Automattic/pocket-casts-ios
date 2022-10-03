import Foundation

extension PCSearchBarController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
        showCancelButton()
        searchDelegate?.searchDidBegin()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchTerm = textField.text, searchTerm.count > 0 {
            textField.resignFirstResponder()
            cancelSearchTimer()
            search(searchTerm: searchTerm, triggerdByTimer: false)
        }

        return true
    }

    @objc func textFieldDidChange() {
        let searchTerm = searchTextField.text

        if let searchTerm = searchTerm, searchTerm.count > 0 {
            clearSearchBtn.isHidden = false
            searchDelegate?.searchTermChanged(searchTerm)
            resetSearchTimer()
        } else {
            clearSearchBtn.isHidden = true
            cancelSearchTimer()
            searchDelegate?.searchWasCleared()
        }
    }
}
