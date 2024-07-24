import SwiftUI
import PocketCastsDataModel

struct AnimatedShareImageView: View {
    let info: ShareImageInfo
    let style: ShareImageStyle

    var body: some View {
        ShareImageView(info: info, style: style)
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

