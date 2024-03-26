import SwiftUI
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import WatchKit

struct InterfaceView: View {
    @StateObject var upNextViewModel: UpNextViewModel
    @StateObject var downloadsViewModel: DownloadListViewModel

    init(source: Source) {
        SourceManager.shared.setSource(newSource: source)
        rowList = SourceManager.shared.isPhone() ? Self.phoneRows : Self.watchRows
        _upNextViewModel = StateObject(wrappedValue: UpNextViewModel())
        _downloadsViewModel = StateObject(wrappedValue: DownloadListViewModel())
    }

    private enum Row: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case nowPlaying, upNext, podcasts, filters, downloads, files
    }
    private static var watchRows: [Row] = [.nowPlaying, .upNext, .podcasts, .filters, .downloads, .files]
    private static var phoneRows: [Row] = [.nowPlaying, .upNext, .filters, .downloads, .files]
    private let rowList: [Row]

    var title: String {
        if SourceManager.shared.isPhone() {
            return L10n.phone.prefixSourceUnicode
        } else {
            return L10n.watch.prefixSourceUnicode
        }
    }

    var body: some View {
        List {
            ForEach(rowList) { row in
                switch row {
                case .downloads:
                    NavigationLink(destination: DownloadListView()) { MenuRow(label: L10n.downloads, icon: "filter_downloaded", count: $downloadsViewModel.downloadedCount) }
                case .podcasts:
                    NavigationLink(destination: PodcastsListView()) { MenuRow(label: L10n.podcastsPlural, icon: "podcasts") }
                case .files:
                    NavigationLink(destination: FilesListView()) { MenuRow(label: L10n.files, icon: "file") }
                case .upNext:
                    NavigationLink(destination: UpNextView()) { MenuRow(label: L10n.upNext, icon: "upnext", count: $upNextViewModel.upNextCount) }
                case .filters:
                    NavigationLink(destination: FiltersListView()) { MenuRow(label: L10n.filters, icon: "filters") }
                case .nowPlaying:
                    NavigationLink(destination: NowPlayingContainerView()) { NowPlayingRow(isPlaying: $upNextViewModel.isPlaying, podcastName: $upNextViewModel.upNextTitle) }
                }
            }
        }
        .navigationTitle(title)
    }
}

#Preview {
    InterfaceView(source: .phone)
}
