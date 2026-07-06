import Foundation
import PocketCastsDataModel

extension Array where Element == Api_AlternateEnclosure {
    /// The HLS stream URL advertised in these alternate enclosures, if one is present.
    /// Mirrors `Episode.hlsUrl(fromEpisodeJson:)` for the protobuf sync path.
    var hlsUrl: String? {
        first { $0.type.caseInsensitiveCompare(Episode.hlsEnclosureType) == .orderedSame }?
            .sources.first?.uri
    }
}
