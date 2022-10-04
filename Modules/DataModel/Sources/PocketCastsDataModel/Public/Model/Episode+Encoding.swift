import Foundation

// I couldn't get either JSONEncoder/JSONDecoder and the property list one to stop crashing when decoding on a series 3 Apple Watch, so here we do it manually
public extension Episode {
    func encodeToMap() -> [String: String] {
        var episodeMap = [String: String]()

        episodeMap["addedDate"] = encode(date: addedDate)
        episodeMap["downloadUrl"] = downloadUrl ?? ""
        episodeMap["episodeDescription"] = episodeDescription ?? ""
        episodeMap["episodeStatus"] = "\(episodeStatus)"
        episodeMap["fileType"] = fileType ?? ""
        episodeMap["keepEpisode"] = "\(keepEpisode)"
        episodeMap["playedUpTo"] = "\(playedUpTo)"
        episodeMap["duration"] = "\(duration)"
        episodeMap["playingStatus"] = "\(playingStatus)"
        episodeMap["publishedDate"] = encode(date: publishedDate)
        episodeMap["title"] = title ?? ""
        episodeMap["uuid"] = uuid
        episodeMap["podcastUuid"] = podcastUuid
        episodeMap["playbackErrorDetails"] = playbackErrorDetails ?? ""
        episodeMap["episodeType"] = episodeType ?? ""
        episodeMap["archived"] = "\(archived)"
        episodeMap["downloadErrorDetails"] = downloadErrorDetails ?? ""
        episodeMap["episodeId"] = "\(id)"
        episodeMap["sizeInBytes"] = "\(sizeInBytes)"
        episodeMap["podcastId"] = "\(podcast_id)"
        episodeMap["episodeNumber"] = "\(episodeNumber)"
        episodeMap["seasonNumber"] = "\(seasonNumber)"

        return episodeMap
    }

    func populateFromMap(_ episodeMap: [String: String]) {
        addedDate = decodeDateFromString(date: episodeMap["addedDate"])
        downloadUrl = episodeMap["downloadUrl"]
        episodeDescription = episodeMap["episodeDescription"]
        episodeStatus = decodeInt32FromString(value: episodeMap["episodeStatus"])
        fileType = episodeMap["fileType"]
        keepEpisode = decodeBoolFromString(value: episodeMap["keepEpisode"])
        playedUpTo = decodeDoubleFromString(value: episodeMap["playedUpTo"])
        duration = decodeDoubleFromString(value: episodeMap["duration"])
        playingStatus = decodeInt32FromString(value: episodeMap["playingStatus"])
        publishedDate = decodeDateFromString(date: episodeMap["publishedDate"])
        title = episodeMap["title"]
        uuid = episodeMap["uuid"] ?? ""
        podcastUuid = episodeMap["podcastUuid"] ?? ""
        playbackErrorDetails = decodeOptionalStringFromString(value: episodeMap["playbackErrorDetails"])
        episodeType = episodeMap["episodeType"]
        archived = decodeBoolFromString(value: episodeMap["archived"])
        downloadErrorDetails = decodeOptionalStringFromString(value: episodeMap["downloadErrorDetails"])
        id = decodeInt64FromString(value: episodeMap["episodeId"])
        sizeInBytes = decodeInt64FromString(value: episodeMap["sizeInBytes"])
        podcast_id = decodeInt64FromString(value: episodeMap["podcastId"])
        episodeNumber = decodeInt64FromString(value: episodeMap["episodeNumber"])
        seasonNumber = decodeInt64FromString(value: episodeMap["seasonNumber"])
    }
}
