import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let gridSize = CGFloat(250)
}

struct PodcastsView<ViewModel: PodcastsViewModelProtocol>: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @Bindable var model: ViewModel

    let gridColumns: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                podcastsView
            case .empty:
                emptyView
            }
        }
        .animation(.easeInOut, value: model.state)
        .task {
            await model.load()
            Analytics.track(.podcastsListShown, properties: [
                "sort_order": model.sortOrder,
                "number_of_podcasts": model.items.filter { $0.podcast != nil }.count,
                "number_of_folders": model.items.filter { $0.folder != nil }.count
            ])
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    @State private var path = NavigationPath()

    var podcastsView: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(L10n.tvTabPodcasts)
                            .font(.title2)
                            .foregroundStyle(Color.pcTextPrimary)
                        Spacer()
                        sortMenu
                    }
                    podcastGrid
                }
            }
        }
        .syncNavigationDetail(path: path, tabRouter: tabRouter)
    }

    var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvPodcastsEmptyTitleNew)
        } description: {
            Text(L10n.tvPodcastsEmptySubtitle)
        } actions: {
            Button(L10n.tvPodcastsEmptyActionTitle) {
                Analytics.track(.podcastsListDiscoverButtonTapped)
                tabRouter.selectedTab = .home
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Section(L10n.sortBy) {
                ForEach(LibrarySort.podcastsListOptions, id: \.self) { order in
                    Button {
                        model.setSortOrder(order)
                    } label: {
                        if model.sortOrder == order {
                            Label(order.description, systemImage: "checkmark")
                        } else {
                            Text(order.description)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(L10n.sortBy)
        }
        .buttonStyle(CircleButtonStyle())
    }

    @Namespace private var podcastGridNamespace

    var podcastGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 48) {
            ForEach(model.items) { item in
                if let podcast = item.podcast {
                    NavigationLink(value: podcast) {
                        PodcastImage(uuid: podcast.uuid, size: .page)
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .focusedCardDepth(cornerRadius: 12, style: .surface)
                    }
                    .buttonStyle(.card)
                    .accessibilityLabel(podcast.title ?? "")
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.track(.podcastsListPodcastTapped)
                    })
                } else if let folder = item.folder {
                    NavigationLink(value: folder) {
                        FolderCardView(folder: folder)
                    }
                    .buttonStyle(.card)
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.track(.podcastsListFolderTapped)
                    })
                }
            }
        }
        .focusScope(podcastGridNamespace)
        .navigationDestination(for: Podcast.self) { podcast in
            PodcastDetailView(podcast: podcast)
        }
        .navigationDestination(for: Folder.self) { folder in
            FolderDetailView(folder: folder)
        }
    }
}

#Preview {
    PodcastsView(model: PodcastsViewModelMock())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
