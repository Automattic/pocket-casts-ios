import Foundation

// I couldn't get either JSONEncoder/JSONDecoder and the property list one to stop crashing when decoding on a series 3 Apple Watch, so here we do it manually
public extension UserEpisode {
    func encodeToMap() -> [String: String] {
        var episodeMap = [String: String]()

        episodeMap["addedDate"] = encode(date: addedDate)
        episodeMap["downloadUrl"] = downloadUrl ?? ""
        episodeMap["episodeStatus"] = "\(episodeStatus)"
        episodeMap["fileType"] = fileType ?? ""
        episodeMap["keepEpisode"] = "\(keepEpisode)"
        episodeMap["playedUpTo"] = "\(playedUpTo)"
        episodeMap["duration"] = "\(duration)"
        episodeMap["playingStatus"] = "\(playingStatus)"
        episodeMap["publishedDate"] = encode(date: publishedDate)
        episodeMap["title"] = title ?? ""
        episodeMap["uuid"] = uuid
        episodeMap["playbackErrorDetails"] = playbackErrorDetails ?? ""
        episodeMap["archived"] = "\(archived)"
        episodeMap["downloadErrorDetails"] = downloadErrorDetails ?? ""
        episodeMap["episodeId"] = "\(id)"
        episodeMap["sizeInBytes"] = "\(sizeInBytes)"
        episodeMap["uploadStatus"] = "\(uploadStatus)"
        episodeMap["imageUrl"] = imageUrl
        episodeMap["imageColor"] = "\(imageColor)"
        episodeMap["hasCustomImage"] = "\(hasCustomImage)"

        return episodeMap
    }

    func populateFromMap(_ episodeMap: [String: String]) {
        addedDate = decodeDateFromString(date: episodeMap["addedDate"])
        downloadUrl = episodeMap["downloadUrl"]
        episodeStatus = decodeInt32FromString(value: episodeMap["episodeStatus"])
        fileType = episodeMap["fileType"]
        keepEpisode = decodeBoolFromString(value: episodeMap["keepEpisode"])
        playedUpTo = decodeDoubleFromString(value: episodeMap["playedUpTo"])
        duration = decodeDoubleFromString(value: episodeMap["duration"])
        playingStatus = decodeInt32FromString(value: episodeMap["playingStatus"])
        publishedDate = decodeDateFromString(date: episodeMap["publishedDate"])
        title = episodeMap["title"]
        uuid = episodeMap["uuid"] ?? ""
        playbackErrorDetails = decodeOptionalStringFromString(value: episodeMap["playbackErrorDetails"])
        archived = decodeBoolFromString(value: episodeMap["archived"])
        downloadErrorDetails = decodeOptionalStringFromString(value: episodeMap["downloadErrorDetails"])
        uploadStatus = decodeInt32FromString(value: episodeMap["uploadStatus"])
        imageUrl = episodeMap["imageUrl"]
        imageColor = decodeInt32FromString(value: episodeMap["imageColor"])
        hasCustomImage = decodeBoolFromString(value: "hasCustomImage")
        id = decodeInt64FromString(value: episodeMap["episodeId"])
        sizeInBytes = decodeInt64FromString(value: episodeMap["sizeInBytes"])
    }
}
