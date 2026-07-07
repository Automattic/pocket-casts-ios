import Foundation
import PocketCastsDataModel

extension Array where Element == Api_AlternateEnclosure {
    /// The HLS stream URL advertised in these alternate enclosures, if one is present.
    /// Mirrors `Episode.hlsUrl(fromEpisodeJson:)` for the protobuf sync path. Normalises the
    /// protobuf default of `""` to `nil` so it isn't persisted as a bogus "missing-but-present" url.
    var hlsUrl: String? {
        let uri = first { $0.type.caseInsensitiveCompare(Episode.hlsEnclosureType) == .orderedSame }?
            .sources.first?.uri
        return (uri?.isEmpty ?? true) ? nil : uri
    }
}
