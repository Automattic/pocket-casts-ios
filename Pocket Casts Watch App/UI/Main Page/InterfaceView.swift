import SwiftUI
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

struct InterfaceView: View {
    @StateObject var upNextViewModel: UpNextViewModel
    @StateObject var downloadsViewModel: DownloadListViewModel
    private let source: Source

    init(source: Source) {
        self.source = source
        rowList = source == .phone ? Self.phoneRows : Self.watchRows
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
        if source == .phone {
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
                    NavigationLink(value: WatchRoute.interface(.downloads)) {
                        MenuRow(label: L10n.downloads, icon: "filter_downloaded", count: $downloadsViewModel.downloadedCount)
                    }
                case .podcasts:
                    NavigationLink(value: WatchRoute.interface(.podcasts)) {
                        MenuRow(label: L10n.podcastsPlural, icon: "podcasts")
                    }
                case .files:
                    NavigationLink(value: WatchRoute.interface(.files)) {
                        MenuRow(label: L10n.files, icon: "file")
                    }
                case .upNext:
                    NavigationLink(value: WatchRoute.interface(.upnext)) {
                        MenuRow(label: L10n.upNext, icon: "upnext", count: $upNextViewModel.upNextCount)
                    }
                case .filters:
                    NavigationLink(value: WatchRoute.interface(.filterList)) {
                        MenuRow(label: L10n.playlists, icon: "filters")
                    }
                case .nowPlaying:
                    NavigationLink(value: WatchRoute.interface(.nowPlaying)) {
                        NowPlayingRow(isPlaying: $upNextViewModel.isPlaying, podcastName: $upNextViewModel.upNextTitle)
                    }
                }
            }
        }
        .restorable(.interface)
        .navigationTitle(title)
    }
}

#Preview {
    InterfaceView(source: .phone)
}
