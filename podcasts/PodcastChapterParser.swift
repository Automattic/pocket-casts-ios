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

    func parseLocalFile(_ path: String, episodeDuration: TimeInterval) async -> [ChapterInfo] {
        await withCheckedContinuation { continuation in
            parseChapters(url: URL(fileURLWithPath: path), episodeDuration: episodeDuration) {
                continuation.resume(returning: $0)
            }
        }
    }

    func parseRemoteFile(_ remoteUrl: String, episodeDuration: TimeInterval) async -> [ChapterInfo] {
        await withCheckedContinuation { continuation in
            guard let url = URL(string: remoteUrl) else {
                continuation.resume(returning: [])
                return
            }

            parseChapters(url: url, episodeDuration: episodeDuration) {
                continuation.resume(returning: $0)
            }
        }
    }

    func parsePodloveChapters(_ podloveChapters: [ShowInfoEpisode.EpisodeChapter], episodeDuration: TimeInterval) -> [ChapterInfo] {
        podloveChapters.enumerated().compactMap { index, chapter in
            let chapterInfo = ChapterInfo()
            chapterInfo.title = chapter.title ?? ""
            chapterInfo.index = index
            chapterInfo.startTime = CMTime(seconds: chapter.startTime, preferredTimescale: 1000000)

            // Calculate chapter duration based on the info we have
            if let endTime = chapter.endTime {
                chapterInfo.duration = endTime - chapter.startTime
            } else if let nextChapterStartTime = podloveChapters[safe: index + 1]?.startTime {
                chapterInfo.duration = nextChapterStartTime - chapter.startTime
            } else {
                chapterInfo.duration = episodeDuration - chapter.startTime
            }

            return chapterInfo
        }
    }

    func parsePodcastIndexChapters(_ podcastIndexChapters: [PodcastIndexChapter], episodeDuration: TimeInterval) -> [ChapterInfo] {
        podcastIndexChapters.enumerated().map { index, chapter in
            let chapterInfo = ChapterInfo()
            chapterInfo.title = chapter.title ?? ""
            chapterInfo.index = chapter.number ?? index
            chapterInfo.startTime = CMTime(seconds: chapter.startTime, preferredTimescale: 1000000)
            if let endTime = chapter.endTime {
                chapterInfo.duration = endTime - chapter.startTime
            } else if let nextChapterStartTime = podcastIndexChapters[safe: index + 1]?.startTime {
                chapterInfo.duration = nextChapterStartTime - chapter.startTime
            } else {
                chapterInfo.duration = episodeDuration - chapter.startTime
            }
            return chapterInfo
        }
    }

    private func parseChapters(url: URL, episodeDuration: TimeInterval, completion: @escaping (([ChapterInfo]) -> Void)) {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                completion([])
                return
            }

            do {
                // wrap chapter parsing in an Objective-C try catch block because we don't want errors from this library to propagate up
                try SJCommonUtils.catchException {
                    let customHeaders = [ServerConstants.HttpHeaders.userAgent: ServerConstants.Values.appUserAgent]
                    let movieAsset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": customHeaders])
                    guard let chapters = MNAVChapterReader.chapters(from: movieAsset) as? [MNAVChapter], chapters.count > 0 else {
                        completion([])
                        return
                    }

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
                        convertedChapter.duration = chapter.duration.seconds
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
}
