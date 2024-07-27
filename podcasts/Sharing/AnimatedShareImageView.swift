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
        GeometryReader { geometry in
            ZStack {
                ShareImageView(info: info, style: style, angle: $angle)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onReceive(animationProgress.$progress) { progress in
                        let calculatedAngle = calculateAngle(progress: Float(progress))
                        angle = Double(calculatedAngle)
//                        print("Update angle: \(angle) for: \(progress)")
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black)
        }
    }

    func update(for progress: Double) {
        animationProgress.progress = progress
//        print("Update progress: \(progress)")
//        let calculatedAngle = calculateAngle(progress: Float(progress))
//        angle = Double(calculatedAngle)
    }

    func calculateAngle(progress: Float) -> Float {
//        let rotationsPerSecond: Float = 0.2
//        let fps = 60
//        let degreesPerProgress: Float = 360.0 / (rotationsPerSecond * Float(fps))
//        let angle = progress * degreesPerProgress
//        return angle

        let angle = (progress * 18000).truncatingRemainder(dividingBy: 360)
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
                    let video = SwiftUIVideoExporter(view: Self(info: info, style: style), duration: CMTimeGetSeconds(duration), size: CGSize(width: 768, height: 1024), audioPlayerItem: playerItem, audioStartTime: startTime, audioDuration: duration)
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
//            itemProvider.registerDataRepresentation(for: .mpeg4Movie) { completion in
//                Task.detached {
//                    let video = SwiftUIVideoExporter(view: Self(info: info, style: style), duration: 60, size: CGSize(width: 768, height: 1024))
//                    let url = FileManager.default.temporaryDirectory.appending(path: "video_export-\(UUID().uuidString).mp4")
//                    try await video.exportToMP4(outputURL: url)
//                    completion(NSItemProvider(contentsOf: url), nil)
//                }
//                return nil
//            }
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

