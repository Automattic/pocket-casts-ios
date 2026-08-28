import SwiftUI

struct NowPlayingContainerView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @State private var selection = 2
    @State private var optionSelected: Bool = false

    var body: some View {
        Group {
            if let _ = viewModel.episode {
                TabView(selection: $selection) {
                    NowPlayingOptions(viewModel: viewModel, optionSelected: $optionSelected)
                        .tag(1)
                        .animation(.none, value: selection)
                    NowPlayingControls(viewModel: viewModel)
                        .tag(2)
                        .animation(.none, value: selection)
                }
                .animation(.easeInOut, value: selection)
            } else {
                NowPlayingEmptyView()
            }
        }
        .navigationTitle(L10n.nowPlayingShortTitle.prefixSourceUnicode)
        .restorable(.nowPlaying)
        .onChange(of: optionSelected) {
            withAnimation {
                selection = 2
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
