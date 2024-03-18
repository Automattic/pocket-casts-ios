import SwiftUI

struct NowPlayingContainerView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @State private var selection = 2
    @State private var presentedView: WatchInterfaceType? = nil
    @State private var optionSelected: Bool = false

    var body: some View {
        Group {
            if let _ = viewModel.episode {
                ZStack {
                    navigationHelpers

                    TabView(selection: $selection) {
                        NowPlayingOptions(viewModel: viewModel, presentView: $presentedView, optionSelected: $optionSelected)
                            .tag(1)
                            .animation(.none)
                        NowPlayingControls(viewModel: viewModel, presentView: $presentedView)
                            .tag(2)
                            .animation(.none)
                    }
                    .animation(.easeInOut)
                }
            } else {
                NowPlayingEmptyView()
            }
        }
        .navigationTitle(L10n.nowPlayingShortTitle.prefixSourceUnicode)
        .restorable(.nowPlaying)
        .onChange(of: optionSelected) { _ in
            withAnimation {
                selection = 2
            }
        }
    }

    // MARK: Navigation

    /// Hidden Navigation items to allow nested screens the ability to push new views outside of the paged TabView
    var navigationHelpers: some View {
        Group {
            NavigationLink(destination: EffectsView(), tag: .effects, selection: $presentedView) {
                EmptyView()
            }.hidden()

            NavigationLink(destination: UpNextView(), tag: .upnext, selection: $presentedView) {
                EmptyView()
            }.hidden()

            if let episode = viewModel.episode {
                NavigationLink(destination: EpisodeView(viewModel: EpisodeDetailsViewModel(episode: episode, playlist: nil), listTitle: L10n.nowPlaying), tag: .episodeDetails, selection: $presentedView) {
                    EmptyView()
                }.hidden()
            }
        }
    }
}

struct NowPlayingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            NowPlayingContainerView()
                .previewDevice($0)
        }
    }
}
