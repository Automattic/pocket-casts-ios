import PocketCastsDataModel
import SwiftUI

struct NowPlayingControls: View {
    @StateObject var viewModel: NowPlayingViewModel
    @Binding var presentView: WatchInterfaceType?

    var body: some View {
        ScrollView([], showsIndicators: false) {
            VStack {
                progressGroup
                    .frame(maxHeight: .infinity)
                plabackGroup
                    .frame(maxHeight: .infinity)
                navigationGroup
                    .frame(maxHeight: .infinity)
                // To take into account the page indicator view
                Spacer().frame(height: Constants.pagingIndicatorHeight)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    private var progressGroup: some View {
        VStack(alignment: .center) {
            Text(viewModel.episodeName)
                .font(.dynamic(size: 14))
                .lineLimit(1)

            LinearProgressView(tintColor: viewModel.episodeAccentColor, progress: $viewModel.progress)

            HStack {
                Text(viewModel.progressTitle)
                    .foregroundColor(viewModel.episodeAccentColor)
                Spacer()
                Text(viewModel.timeRemaining)
            }
            .font(.dynamic(size: 13))
        }
    }

    private var plabackGroup: some View {
        HStack {
            Button {
                WKInterfaceDevice.current().play(.click)
                viewModel.skip(forward: false)
            } label: {
                Image("skipback", bundle: .watchAssets)
                    .playGroupStlyed()
            }

            Spacer()
            playPauseButton
            Spacer()

            Button {
                WKInterfaceDevice.current().play(.click)
                viewModel.skip(forward: true)
            } label: {
                Image("skipforward", bundle: .watchAssets)
                    .playGroupStlyed()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 32, idealHeight: 40, maxHeight: 44)
    }

    private var playPauseButton: some View {
        Button {
            WKInterfaceDevice.current().play(viewModel.isPlaying ? .click : .start)
            viewModel.playPauseTapped()
        } label: {
            Image(viewModel.isPlaying ? "pause" : "play")
                .playGroupStlyed()
        }
        .accessibilityLabel(viewModel.isPlaying ? L10n.pause : L10n.play)
    }

    private var navigationGroup: some View {
        HStack {
            Button {
                WKInterfaceDevice.current().play(.click)
                presentView = .effects
            } label: {
                Image(viewModel.effectsIconName)
            }

            Spacer()
            VolumeControl(tint: viewModel.episodeAccentColor)
            Spacer()

            Button {
                WKInterfaceDevice.current().play(.click)
                presentView = .upnext
            } label: {
                switch viewModel.upNextCount {
                case 0 ... 8:
                    Image("upnext-\(viewModel.upNextCount)")
                default:
                    Image("upnext-9+")
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 2)
    }

    private enum Constants {
        static let pagingIndicatorHeight: CGFloat = 5
    }
}

private extension Image {
    func playGroupStlyed() -> some View {
        resizable()
            .aspectRatio(1, contentMode: .fit)
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            NowPlayingControls(viewModel: NowPlayingViewModel(), presentView: .constant(nil))
                .previewDevice($0)
        }
    }
}
