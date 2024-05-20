import Foundation

extension UITableView {
    func applyInsetForMiniPlayer(additionalBottomInset: CGFloat = 0) {
        let existingInset = contentInset
        contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: existingInset.bottom + Constants.Values.miniPlayerOffset + additionalBottomInset, right: existingInset.right)
    }

    func updateContentInset(multiSelectEnabled: Bool) {
        let existingInset = contentInset
        let multiSelectFooterOffset: CGFloat = multiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: miniPlayerOffset + multiSelectFooterOffset, right: existingInset.right)
    }
}
