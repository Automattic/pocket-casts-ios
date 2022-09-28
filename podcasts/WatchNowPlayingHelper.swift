import Foundation
import MediaPlayer
import PocketCastsDataModel

class WatchNowPlayingHelper {
    class func updateNowPlayingInfo(for episode: BaseEpisode, duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) {
        guard let currNowPlaying = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            setAllNowPlayingInfo(for: episode, duration: duration, upTo: upTo, playbackRate: playbackRate)
            return
        }

        let title = WatchNowPlayingHelper.titleForNowPlayingInfo(episode: episode)
        // there's a lot of weird edge case bugs with Apple's now playing implementation, so this method gets called every time progress
        // is saved to the DB, currently every updatesPerSave seconds. it looks at what's in their at the moment, and if it's not the current episode
        // sets all the data, otherwise is just updates the progress
        let nowPlayingTitle = currNowPlaying[MPMediaItemPropertyTitle] as? String
        if title == nowPlayingTitle {
            let nowPlayingInfo = WatchNowPlayingHelper.addUpToInformationToNowPlaying(currNowPlaying as [String: AnyObject], duration: duration, upTo: upTo, playbackRate: playbackRate)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else {
            setAllNowPlayingInfo(for: episode, duration: duration, upTo: upTo, playbackRate: playbackRate)
        }
    }

    class func setAllNowPlayingInfo(for episode: BaseEpisode, duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) {
        let playingInfo = nowPlayingInfo(for: episode)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = WatchNowPlayingHelper.addUpToInformationToNowPlaying(playingInfo, duration: duration, upTo: upTo, playbackRate: playbackRate)
    }

    class func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private class func titleForNowPlayingInfo(episode: BaseEpisode) -> String {
        episode.displayableTitle()
    }

    private class func nowPlayingInfo(for episode: BaseEpisode) -> [String: AnyObject] {
        var nowPlayingInfo = [String: AnyObject]()

        let nowPlayingMediaType = episode.videoPodcast() ? MPNowPlayingInfoMediaType.video.rawValue : MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: nowPlayingMediaType)
        nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyDiscCount] = NSNumber(value: 1)
        nowPlayingInfo[MPMediaItemPropertyDiscNumber] = NSNumber(value: 1)

        let episodeTitle = titleForNowPlayingInfo(episode: episode)
        if episodeTitle.count > 0 {
            nowPlayingInfo[MPMediaItemPropertyTitle] = episodeTitle as NSString
        }

        // duration
        if episode.duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: episode.duration)
            nowPlayingInfo[MPMediaItemPropertyBookmarkTime] = NSNumber(value: episode.playedUpTo)
        }

        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.subTitle() as NSString
        nowPlayingInfo[MPMediaItemPropertyComposer] = episode.subTitle() as NSString
        nowPlayingInfo[MPMediaItemPropertyGenre] = "Podcast" as NSString

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
