import Foundation
import PocketCastsDataModel
import PocketCastsServer
import WatchKit

class InterfaceController: PCInterfaceController {
    static let controllerRestoreName = "InterfaceController"

    @IBOutlet var mainTable: WKInterfaceTable!
    @IBOutlet var connectionErrorLabel: WKInterfaceLabel!

    private enum row { case nowPlaying, upNext, podcasts, filters, downloads, files }
    private var watchRows: [row] = [.nowPlaying, .upNext, .podcasts, .filters, .downloads, .files]
    private var phoneRows: [row] = [.nowPlaying, .upNext, .filters, .downloads, .files]

    override func addAdditionalObservers() {
        guard SourceManager.shared.isWatch() else { return }
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(updateNowPlaying))
    }

    override func handleDataUpdated() {
        let sourceIsPhone = SourceManager.shared.isPhone()
        let rowList = sourceIsPhone ? phoneRows : watchRows
        let rowCount = rowList.count

        var rowTypes = Array(repeating: "TopLevelItemRowController", count: rowCount - 1)
        rowTypes.insert("NowPlayingRowController", at: 0)
        mainTable.setRowTypes(rowTypes)

        for rowIndex in 0 ... rowCount - 1 {
            let thisRow = rowList[rowIndex]
            switch thisRow {
            case .nowPlaying:
                let nowPlayingRow = mainTable.rowController(at: rowIndex) as! NowPlayingRowController
                updateNowPlayingRow(rowController: nowPlayingRow)
            case .upNext:
                let upNextRow = mainTable.rowController(at: rowIndex) as! TopLevelItemRowController
                upNextRow.icon.setImage(UIImage(named: "upnext"))
                upNextRow.episodeCountGroup.setHidden(false)
                let upNextCount = sourceIsPhone ? WatchDataManager.upNextCount() : PlaybackManager.shared.queue.upNextCount()
                upNextRow.populate(title: L10n.upNext, count: upNextCount)
            case .podcasts:
                let podcastsRow = mainTable.rowController(at: rowIndex) as! TopLevelItemRowController
                podcastsRow.populate(title: L10n.podcastsPlural)
                podcastsRow.icon.setImage(UIImage(named: "podcasts"))
            case .filters:
                let filtersRow = mainTable.rowController(at: rowIndex) as! TopLevelItemRowController
                filtersRow.populate(title: L10n.filters)
                filtersRow.icon.setImage(UIImage(named: "filters"))
            case .downloads:
                let downloadsRow = mainTable.rowController(at: rowIndex) as! TopLevelItemRowController
                downloadsRow.icon.setImage(UIImage(named: "filter_downloaded"))
                let downloadCount = sourceIsPhone ? 0 : DataManager.sharedManager.downloadedEpisodeCount()
                downloadsRow.populate(title: L10n.downloads, count: downloadCount)
            case .files:
                let filesRow = mainTable.rowController(at: rowIndex) as! TopLevelItemRowController
                filesRow.populate(title: L10n.files)
                filesRow.icon.setImage(UIImage(named: "file"))
            }
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let rowList = SourceManager.shared.isPhone() ? phoneRows : watchRows
        let row = rowList[rowIndex]

        switch row {
        case .nowPlaying:
            pushController(forType: .nowPlaying)
        case .upNext:
            pushController(forType: .upnext)
        case .podcasts:
            pushController(forType: .podcasts)
        case .filters:
            pushController(withName: "FiltersInterfaceController", context: nil)
        case .downloads:
            pushController(forType: .downloads)
        case .files:
            pushController(forType: .files)
        }
    }

    @objc private func updateNowPlaying() {
        guard let nowPlayingRow = mainTable.rowController(at: 0) as? NowPlayingRowController else { return }

        updateNowPlayingRow(rowController: nowPlayingRow)
    }

    private func updateNowPlayingRow(rowController: NowPlayingRowController) {
        let sourceIsPhone = SourceManager.shared.isPhone()
        let playing = sourceIsPhone ? WatchDataManager.isPlaying() : PlaybackManager.shared.playing()
        let podcastName = sourceIsPhone ? WatchDataManager.playingEpisode()?.subTitle() : PlaybackManager.shared.currentEpisode()?.subTitle()

        rowController.setNowPlayingInfo(isPlaying: playing, podcastName: podcastName)
    }

    override func populateTitle() {
        if SourceManager.shared.isPhone() {
            setTitle(L10n.phone.prefixSourceUnicode)
        } else {
            setTitle(L10n.watch.prefixSourceUnicode)
        }
    }

    // MARK: - Restorable Support

    override func restoreName() -> String? {
        InterfaceController.controllerRestoreName
    }
}
