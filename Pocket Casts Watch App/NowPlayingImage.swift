import Combine
import SwiftUI

struct NowPlayingImage: View {
    private let timer = Timer.publish(every: 0.03, on: .main, in: .default).autoconnect()

    @Binding var isPlaying: Bool
    @State private var imageIndex: Int = 0
    @State private var images: [Image] = (1 ... 60).map {
        Image("nowplaying\($0)", bundle: .watchAssets)
    }

    var body: some View {
        Group {
            if self.isPlaying {
                images[imageIndex]
            } else {
                Image("notplaying", bundle: .watchAssets)
            }
        }
        .onReceive(timer) { _ in
            imageIndex = imageIndex + 1
            if imageIndex > images.count - 1 { imageIndex = 0 }
        }
    }
}

struct NowPlayingImage_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingImage(isPlaying: .constant(false))
            .frame(width: 48, height: 48)
            .previewDevice(.largeWatch)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
