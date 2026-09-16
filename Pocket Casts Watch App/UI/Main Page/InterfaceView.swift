import SwiftUI
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

struct InterfaceView: View {
    @EnvironmentObject var navigationModel: NavigationManager

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
                    link(to: .downloads) {
                        MenuRow(label: L10n.downloads, icon: "filter_downloaded", count: $downloadsViewModel.downloadedCount)
                    }
                case .podcasts:
                    link(to: .podcasts) {
                        MenuRow(label: L10n.podcastsPlural, icon: "podcasts")
                    }
                case .files:
                    link(to: .files) {
                        MenuRow(label: L10n.files, icon: "file")
                    }
                case .upNext:
                    link(to: .upnext) {
                        MenuRow(label: L10n.upNext, icon: "upnext", count: $upNextViewModel.upNextCount)
                    }
                case .filters:
                    link(to: .filterList) {
                        MenuRow(label: L10n.playlists, icon: "filters")
                    }
                case .nowPlaying:
                    link(to: .nowPlaying) {
                        NowPlayingRow(isPlaying: $upNextViewModel.isPlaying, podcastName: $upNextViewModel.upNextTitle)
                            .padding(-4)
                    }
                }
            }
        }
        .navigationDestination(item: $navigationModel.currentInterface) { type in
            destination(for: type)
        }
        .restorable(.interface)
        .navigationTitle(title)
    }

    private func link(to type: WatchInterfaceType, @ViewBuilder label: () -> some View) -> some View {
        Button {
            navigationModel.currentInterface = type
        } label: {
            label()
        }
    }

    @ViewBuilder
    private func destination(for type: WatchInterfaceType) -> some View {
        switch type {
        case .downloads:
            DownloadListView()
        case .podcasts:
            PodcastsListView()
        case .files:
            FilesListView()
        case .upnext:
            UpNextView()
        case .filterList:
            PlaylistsListView()
        case .nowPlaying:
            NowPlayingContainerView()
        case .unknown, .effects, .episodeDetails, .filter, .interface:
            EmptyView()
        }
    }
}

#Preview {
    InterfaceView(source: .phone)
}
