import SwiftUI

struct DownloadProgressEpisodeActionView: View {
    @Binding var downloadProgress: DownloadProgress?

    var body: some View {
        EpisodeActionView(iconName: downloadIconForProgress(downloadProgress), title: EpisodeAction.pauseDownload.title)
    }

    private func downloadIconForProgress(_ progress: DownloadProgress?) -> String {
        guard let progress = progress else {
            return EpisodeAction.pauseDownload.iconName
        }

        let progressNumber = max(1, Int(ceil(progress.percentageProgress() / 100.0 * 16.0)))
        if progressNumber < 10 {
            return "episode_download_0\(progressNumber)"
        }

        return "episode_download_\(progressNumber)"
    }
}

struct DownloadProgressActionView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadProgressEpisodeActionView(downloadProgress: .constant(nil))
            .previewDevice(.largeWatch)
    }
}
