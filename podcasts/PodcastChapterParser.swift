import AVFoundation
import Foundation
import PocketCastsServer
import PocketCastsUtils

class PodcastChapterParser {
    func parseLocalFile(_ path: String, episodeDuration: TimeInterval, completion: @escaping (([ChapterInfo]) -> Void)) {
        parseChapters(url: URL(fileURLWithPath: path), episodeDuration: episodeDuration, completion: completion)
    }

    func parseRemoteFile(_ remoteUrl: String, episodeDuration: TimeInterval, completion: @escaping (([ChapterInfo]) -> Void)) {
        guard let url = URL(string: remoteUrl) else { return }

        parseChapters(url: url, episodeDuration: episodeDuration, completion: completion)
    }

    private func parseChapters(url: URL, episodeDuration: TimeInterval, completion: @escaping (([ChapterInfo]) -> Void)) {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }

            do {
                // wrap chapter parsing in an Objective-C try catch block because we don't want errors from this library to propagate up
                try SJCommonUtils.catchException {
                    let customHeaders = [ServerConstants.HttpHeaders.userAgent: ServerConstants.Values.appUserAgent]
                    let movieAsset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": customHeaders])
                    guard let chapters = MNAVChapterReader.chapters(from: movieAsset) as? [MNAVChapter], chapters.count > 0 else { return }

                    if chapters.allSatisfy({ $0.hidden }) {
                        chapters.forEach { $0.hidden = false }
                    }

                    var parsedChapters = [ChapterInfo]()
                    var index = 0
                    for chapter in chapters {
                        let convertedChapter = ChapterInfo()
                        convertedChapter.title = chapter.title ?? ""
                        #if !os(watchOS)
                            convertedChapter.image = chapter.artwork
                        #endif

                        convertedChapter.startTime = chapter.time
                        convertedChapter.duration = strongSelf.sanitise(chapterDuration: chapter.duration.seconds, usingChapterStart: chapter.time, episodeDuration: episodeDuration)
                        convertedChapter.isHidden = chapter.hidden
                        if !convertedChapter.isHidden {
                            convertedChapter.index = index
                            index += 1
                        }
                        if strongSelf.isValidUrl(chapter.url) {
                            convertedChapter.url = chapter.url
                        }

                        parsedChapters.append(convertedChapter)
                    }
                    parsedChapters.first(where: {!$0.isHidden})?.isFirst = true
                    parsedChapters.last(where: {!$0.isHidden})?.isLast = true
                    completion(parsedChapters)
                }
            } catch {
                FileLog.shared.addMessage("Encountered crash while trying to parse chapters \(error)")
            }
        }
    }

    private func isValidUrl(_ urlStr: String?) -> Bool {
        // first check can we actually make a URL out of this string and does it have a scheme?
        guard let urlStr = urlStr, let url = URL(string: urlStr), let scheme = url.scheme else { return false }

        // next see if the scheme is http or https, we don't support any others
        return scheme.caseInsensitiveCompare("http") == .orderedSame || scheme.caseInsensitiveCompare("https") == .orderedSame
    }

    private func sanitise(chapterDuration: TimeInterval, usingChapterStart chapterStart: CMTime, episodeDuration: TimeInterval) -> TimeInterval {
        let sanitisedDuration = chapterStart.seconds + chapterDuration > episodeDuration ? episodeDuration - chapterStart.seconds : chapterDuration

        return sanitisedDuration
    }
}
