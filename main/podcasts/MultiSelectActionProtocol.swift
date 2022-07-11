import Foundation
import PocketCastsDataModel
protocol MultiSelectActionDelegate: AnyObject {
    func multiSelectPresentingViewController() -> UIViewController
    func multiSelectedBaseEpisodes() -> [BaseEpisode]
    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]?
    func multiSelectActionBegan(status: String)
    func multiSelectActionCompleted()
    func multiSelectPreferredStatusBarStyle() -> UIStatusBarStyle
}
