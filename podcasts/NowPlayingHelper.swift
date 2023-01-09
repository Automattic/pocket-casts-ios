import Foundation
import MediaPlayer
import PocketCastsDataModel
import PocketCastsUtils

class NowPlayingHelper {
    class func updateNowPlayingInfo(for episode: BaseEpisode, currentChapters: Chapters, duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) {
        guard let currNowPlaying = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            setAllNowPlayingInfo(for: episode, currentChapters: currentChapters, duration: duration, upTo: upTo, playbackRate: playbackRate)
            return
        }

        let title = NowPlayingHelper.titleForNowPlayingInfo(episode: episode, currentChapters: currentChapters)
        // there's a lot of weird edge case bugs with Apple's now playing implementation, so this method gets called every time progress
        // is saved to the DB, currently every updatesPerSave seconds. it looks at what's in their at the moment, and if it's not the current episode
        // sets all the data, otherwise is just updates the progress
        let nowPlayingTitle = currNowPlaying[MPMediaItemPropertyTitle] as? String
        if title == nowPlayingTitle {
            let nowPlayingInfo = NowPlayingHelper.addUpToInformationToNowPlaying(currNowPlaying as [String: AnyObject], duration: duration, upTo: upTo, playbackRate: playbackRate)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else {
            setAllNowPlayingInfo(for: episode, currentChapters: currentChapters, duration: duration, upTo: upTo, playbackRate: playbackRate)
        }
    }

    class func setAllNowPlayingInfo(for episode: BaseEpisode, currentChapters: Chapters, duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) {
        let playingInfo = nowPlayingInfo(for: episode, currentChapters: currentChapters)
        var nowPlayingInfoWithProgress = NowPlayingHelper.addUpToInformationToNowPlaying(playingInfo, duration: duration, upTo: upTo, playbackRate: playbackRate)

        let size = ImageManager.sizeFor(imageSize: .page)
        ImageManager.sharedManager.imageForEpisode(episode, size: .page) { image in
            let imageToUse = image ?? UIImage(named: "noartwork-page")!

            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: size, height: size), requestHandler: { _ -> UIImage in
                imageToUse
            })

            nowPlayingInfoWithProgress[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfoWithProgress
        }
    }

    class func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private class func titleForNowPlayingInfo(episode: BaseEpisode, currentChapters: Chapters) -> String {
        if currentChapters.title.count > 0, Settings.publishChapterTitlesEnabled() {
            return currentChapters.title
        }

        if let podcastEpisode = episode as? Episode, podcastEpisode.episodeNumber > 0 {
            let suffix = L10n.seasonEpisodeShorthand(seasonNumber: podcastEpisode.seasonNumber, episodeNumber: podcastEpisode.episodeNumber, shortFormat: true)
            return "\(episode.displayableTitle()) (\(suffix))"
        }

        return episode.displayableTitle()
    }

    private class func nowPlayingInfo(for episode: BaseEpisode, currentChapters: Chapters) -> [String: AnyObject] {
        var nowPlayingInfo = [String: AnyObject]()

        nowPlayingInfo[MPMediaItemPropertyMediaType] = NSNumber(value: MPMediaType.podcast.rawValue)
        let nowPlayingMediaType = episode.videoPodcast() ? MPNowPlayingInfoMediaType.video.rawValue : MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: nowPlayingMediaType)
        nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyDiscCount] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyDiscNumber] = NSNumber(value: 1)

        let episodeTitle = titleForNowPlayingInfo(episode: episode, currentChapters: currentChapters)
        if episodeTitle.count > 0 {
            nowPlayingInfo[MPMediaItemPropertyTitle] = episodeTitle as NSString
        }

        // duration
        if episode.duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: episode.duration)
            nowPlayingInfo[MPMediaItemPropertyBookmarkTime] = NSNumber(value: episode.playedUpTo)
        }

        if let episode = episode as? Episode, let parentPodcast = episode.parentPodcast() {
            // some car stereo's do weird things with the % character, so here we replace it with pct to work around those bugs
            let safeCharacterPodcastTitle = parentPodcast.title?.replacingOccurrences(of: "%", with: "pct") ?? "Pocket Casts"
            let safeCharacterPodcastAuthor = parentPodcast.author?.replacingOccurrences(of: "%", with: "pct") ?? "Pocket Casts"

            nowPlayingInfo[MPMediaItemPropertyArtist] = safeCharacterPodcastAuthor as NSString
            nowPlayingInfo[MPMediaItemPropertyComposer] = safeCharacterPodcastAuthor as NSString

            // we purposely show the date here instead, but as with the above there's a car stereo bug we need to work around as well where we don't show the word "Wednesday" in the artist field
            // because on some car stereos that have embedded image databases, this comes up with a really grotesque image (more info: https://github.com/shiftyjelly/pocketcasts-ios/issues/3874)
            let publishedDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).replacingOccurrences(of: "Wednesday", with: "Wed", options: .caseInsensitive)
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = publishedDate as NSString

            nowPlayingInfo[MPMediaItemPropertyPodcastTitle] = safeCharacterPodcastTitle as NSString

            // genre
            if let podcastCategory = parentPodcast.podcastCategory, podcastCategory.count > 0 {
                nowPlayingInfo[MPMediaItemPropertyGenre] = podcastCategory as NSString
            } else {
                nowPlayingInfo[MPMediaItemPropertyGenre] = "Podcast" as NSString
            }
        } else {
            nowPlayingInfo[MPMediaItemPropertyArtist] = "PocketCasts" as NSString
            nowPlayingInfo[MPMediaItemPropertyComposer] = "PocketCasts" as NSString
            nowPlayingInfo[MPMediaItemPropertyGenre] = "Podcast" as NSString
        }

        return nowPlayingInfo
    }

    private class func addUpToInformationToNowPlaying(_ nowPlaying: [String: AnyObject], duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) -> [String: AnyObject] {
        var nowPlayingClone = nowPlaying

        nowPlayingClone[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
        nowPlayingClone[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: upTo)
        if let playbackRate = playbackRate {
            nowPlayingClone[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: playbackRate)
            nowPlayingClone[MPNowPlayingInfoPropertyDefaultPlaybackRate] = NSNumber(value: playbackRate)
        } else {
            nowPlayingClone[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 0)
        }

        return nowPlayingClone
    }
}
