import SwiftUI
import PocketCastsDataModel

class AnimationProgress: ObservableObject {
    @Published var progress: Double = 0 // O-1
}

struct AnimatedShareImageView: AnimatableContent {
    let info: ShareImageInfo
    let style: ShareImageStyle

    @State var angle: Double = 0
    @ObservedObject var animationProgress: AnimationProgress = .init()

    var body: some View {
        ZStack {
            ShareImageView(info: info, style: style, angle: $angle)
                .onReceive(animationProgress.$progress) { progress in
                    let calculatedAngle = calculateAngle(progress: Float(progress))
                    angle = Double(calculatedAngle)
                }
                .scaleEffect(CGSize(width: 2.0, height: 2.0))
        }
    }

    func update(for progress: Double) {
        animationProgress.progress = progress
    }

    func calculateAngle(progress: Float) -> Float {
        let angle = (progress * 1800).truncatingRemainder(dividingBy: 360)
        return angle
    }
}

extension AnimatedShareImageView {
    func itemProvider(episode: some BaseEpisode, startTime: CMTime, duration: CMTime) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        if #available(iOS 16.0, *) {
            itemProvider.registerFileRepresentation(for: .mpeg4Movie) { completion in
                let progress = Progress()
                Task.detached {
                    guard let playerItem = DownloadManager.shared.downloadParallelToStream(of: episode) else {
                        completion(nil, false, nil)
                        return
                    }
                    let size = CGSize(width: style.videoSize.width * 2, height: style.videoSize.height * 2)
                    let video = SwiftUIVideoExporter(view: Self(info: info, style: style), duration: CMTimeGetSeconds(duration), size: size, audioPlayerItem: playerItem, audioStartTime: startTime, audioDuration: duration)
                    let url = FileManager.default.temporaryDirectory.appending(path: "video_export-\(UUID().uuidString).mp4")

                    do {
                        try await video.exportToMP4(outputURL: url, progress: progress)
                    } catch let error {
                        completion(url, true, error)
                    }

                    completion(url, true, nil)
                }

                return progress
            }
        } else {
            itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.mpeg4Movie.identifier, visibility: .all) { completion in
                Task.detached {
                    await completion(snapshot().pngData(), nil)
                }
                return nil
            }
        }
        return itemProvider
    }
}
