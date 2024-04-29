import Foundation

extension UITableView {
    func applyInsetForMiniPlayer(additionalBottomInset: CGFloat = 0) {
        let existingInset = contentInset
        contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: existingInset.bottom + Constants.Values.miniPlayerOffset + additionalBottomInset, right: existingInset.right)

        let existingScrollIndicatorInset = verticalScrollIndicatorInsets
        scrollIndicatorInsets = UIEdgeInsets(top: existingScrollIndicatorInset.top, left: existingScrollIndicatorInset.left, bottom: existingScrollIndicatorInset.bottom + Constants.Values.miniPlayerOffset + additionalBottomInset, right: existingScrollIndicatorInset.right)
    }

    func updateContentInset(multiSelectEnabled: Bool) {
        let multiSelectFooterOffset: CGFloat = multiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerOffset + multiSelectFooterOffset, right: 0)
        scrollIndicatorInsets = contentInset
    }
}
