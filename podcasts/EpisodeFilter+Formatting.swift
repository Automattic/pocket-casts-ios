import Foundation
import PocketCastsDataModel

extension EpisodeFilter {
    #if !os(watchOS)
        class func indexOf(color: UIColor) -> Int {
            if AppTheme.playlistRedColor().isEqual(color) {
                return 0
            } else if AppTheme.playlistBlueColor().isEqual(color) {
                return 1
            } else if AppTheme.playlistGreenColor().isEqual(color) {
                return 2
            } else if AppTheme.playlistPurpleColor().isEqual(color) {
                return 3
            }

            return 4
        }
    #endif
    func iconImage() -> UIImage? {
        guard let icon = PlaylistIcon(rawValue: customIcon) else { return nil }

        return EpisodeFilter.imageForPlaylistIcon(icon: icon)
    }

    func iconImageLarge() -> UIImage? {
        guard let iconName = iconImageNameLarge() else { return nil }

        return UIImage(named: iconName)
    }

    func iconImageNameLarge() -> String? {
        guard let regularName = iconImageName() else { return nil }

        return "\(regularName)_large"
    }

    func iconImageName() -> String? {
        guard let icon = PlaylistIcon(rawValue: customIcon) else { return nil }

        return EpisodeFilter.imageName(forPlaylistIcon: icon)
    }

    #if !os(watchOS)
        func iconImageNameCarPlay() -> String {
            guard let regularName = iconImageName() else { return "" }

            var name = "car_\(regularName)"

            let color = playlistColor()
            if color == AppTheme.playlistRedColor() {
                name += "_red"
            } else if color == AppTheme.playlistGreenColor() {
                name += "_green"
            } else if color == AppTheme.playlistYellowColor() {
                name += "_yellow"
            } else if color == AppTheme.playlistPurpleColor() {
                name += "_purple"
            } else {
                name += "_blue" // default to blue
            }

            return name
        }
    #endif

    class func imageForPlaylistIcon(icon: PlaylistIcon) -> UIImage? {
        guard let name = imageName(forPlaylistIcon: icon) else { return nil }

        return UIImage(named: name)
    }

    class func imageName(forPlaylistIcon icon: PlaylistIcon) -> String? {
        if icon == .redPlaylist || icon == .bluePlaylist || icon == .greenPlaylist || icon == .purplePlaylist || icon == .yellowPlaylist {
            return "filter_list"
        } else if icon == .redmostPlayed || icon == .bluemostPlayed || icon == .greenmostPlayed || icon == .purplemostPlayed || icon == .yellowmostPlayed {
            return "filter_headphones"
        } else if icon == .redRecent || icon == .blueRecent || icon == .greenRecent || icon == .purpleRecent || icon == .yellowRecent {
            return "filter_clock"
        } else if icon == .redDownloading || icon == .blueDownloading || icon == .greenDownloading || icon == .purpleDownloading || icon == .yellowDownloading {
            return "filter_downloaded"
        } else if icon == .redUnplayed || icon == .blueUnplayed || icon == .greenUnplayed || icon == .purpleUnplayed || icon == .yellowUnplayed {
            return "filter_play"
        } else if icon == .redAudio || icon == .blueAudio || icon == .greenAudio || icon == .purpleAudio || icon == .yellowAudio {
            return "filter_volume"
        } else if icon == .redVideo || icon == .blueVideo || icon == .greenVideo || icon == .purpleVideo || icon == .yellowVideo {
            return "filter_video"
        } else if icon == .redTop || icon == .blueTop || icon == .greenTop || icon == .purpleTop || icon == .yellowTop {
            return "filter_starred"
        }

        return nil
    }

    #if !os(watchOS)
        func setPlaylistColor(color: UIColor) {
            let currentIcon = Int(customIcon)
            let currentIconRow = Int(currentIcon / EpisodeFilter.iconsPerType)
            let newIcon = (currentIconRow * EpisodeFilter.iconsPerType) + EpisodeFilter.indexOf(color: color)

            customIcon = Int32(newIcon)
            syncStatus = SyncStatus.notSynced.rawValue
            DataManager.sharedManager.save(playlist: self)
        }

        func playlistColor() -> UIColor {
            AppTheme.colorForStyle(playlistStyle())
        }

        func playlistStyle() -> ThemeStyle {
            guard let icon = PlaylistIcon(rawValue: customIcon) else { return .filter01 }

            switch icon {
            case .redPlaylist, .redmostPlayed, .redRecent, .redDownloading, .redUnplayed, .redAudio, .redVideo, .redTop:
                return .filter01
            case .bluePlaylist, .bluemostPlayed, .blueRecent, .blueDownloading, .blueUnplayed, .blueAudio, .blueVideo, .blueTop:
                return .filter05
            case .greenPlaylist, .greenmostPlayed, .greenRecent, .greenDownloading, .greenUnplayed, .greenAudio, .greenVideo, .greenTop:
                return .filter04
            case .purplePlaylist, .purplemostPlayed, .purpleRecent, .purpleDownloading, .purpleUnplayed, .purpleAudio, .purpleVideo, .purpleTop:
                return .filter06
            case .yellowPlaylist, .yellowmostPlayed, .yellowRecent, .yellowDownloading, .yellowUnplayed, .yellowAudio, .yellowVideo, .yellowTop:
                return .filter03
            }
        }
    #endif

    func maxAutoDownloadEpisodes() -> Int32 {
        autoDownloadLimit == 0 ? Constants.Values.defaultPlaylistDownloadLimit : autoDownloadLimit
    }

    func episodeUuidToAddToQueries() -> String? {
        if let playingEpisode = PlaybackManager.shared.currentEpisode(), PlaybackManager.shared.uuidOfPlayingList == uuid {
            return playingEpisode.uuid
        }

        return nil
    }
}
