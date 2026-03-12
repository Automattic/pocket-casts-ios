import SwiftUI

struct UpNextView: View {
    @StateObject var viewModel: UpNextViewModel
    @State private var presentClearPrompt = false

    init() {
        _viewModel = StateObject(wrappedValue: UpNextViewModel())
    }

    var body: some View {
        ItemListContainer(isEmpty: viewModel.isEmpty, noItemsTitle: L10n.watchUpNextNoItemsTitle, noItemsSubtitle: L10n.watchUpNextNoItemsSubtitle) {
            List {
                NowPlayingRow(isPlaying: $viewModel.isPlaying, podcastName: $viewModel.upNextTitle)
                EpisodeListView(title: L10n.settingsFiles.prefixSourceUnicode, showArtwork: true, episodes: $viewModel.episodes, playlist: nil)
                    .padding(.vertical, 10)
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentClearPrompt.toggle()
                    } label: {
                        HStack {
                            Image("markasplayed", bundle: Bundle.watchAssets)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(L10n.removeAll)
                                .font(.dynamic(size: 16))
                            Spacer()
                        }
                    }
                    .padding(.vertical)
                    .accentColor(.background)
                }
            }
            .actionSheet(isPresented: $presentClearPrompt) {
                ActionSheet(
                    title: Text(L10n.clearUpNext),
                    message: Text(L10n.clearUpNextMessage),
                    buttons: [.destructive(Text(L10n.clear), action: { viewModel.clearUpNext() })]
                )
            }
        }
        .navigationTitle(L10n.upNext.prefixSourceUnicode)
        .restorable(.upnext)
    }
}

struct UpNextView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            UpNextView()
                .previewDevice($0)
        }
    }
}
