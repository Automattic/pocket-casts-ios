import Foundation
import PocketCastsDataModel

@MainActor
protocol MultiSelectActionDelegate: AnyObject, Sendable {
    func multiSelectPresentingViewController() -> UIViewController
    func multiSelectedBaseEpisodes() -> [BaseEpisode]
    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]?
    func multiSelectActionBegan(status: String)
    func multiSelectActionCompleted()
    func multiSelectPreferredStatusBarStyle() -> UIStatusBarStyle
    var multiSelectViewSource: AnalyticsSource { get }
}
