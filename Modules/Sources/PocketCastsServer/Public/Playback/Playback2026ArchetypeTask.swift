import Foundation
import PocketCastsUtils

/// A Playback 2026 listener archetype.
public enum Playback2026Archetype: String, CaseIterable, Sendable {
    case flaneur
    case avantGardist
    case collector
    case aficionado
    case anthologist
}

/// Asks the server for the signed-in user's Playback 2026 listener archetype.
///
/// The server works it out from the user's whole year, against figures for every show and every
/// listener that the device doesn't have, and stores it the first time it's asked: after launch,
/// it's the same on every device and every time.
public struct Playback2026ArchetypeTask: @unchecked Sendable {
    public enum Playback2026ArchetypeError: Error {
        case requestFailed(statusCode: Int)
        case unknownArchetype(rawValue: Int)
    }

    private let tokenHelper: TokenHelper

    public init() {
        self.init(tokenHelper: .shared)
    }

    init(tokenHelper: TokenHelper) {
        self.tokenHelper = tokenHelper
    }

    public func archetype() async throws -> Playback2026Archetype {
        let url = try URL(throwing: ServerConstants.Urls.api() + "user/playback-2026/archetype")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.seconds)
        request.httpMethod = "GET"
        request.setValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        request.setValue("application/octet-stream", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.addLocalizationHeaders()

        let (response, data) = try await tokenHelper.callSecureUrl(request: request)

        let statusCode = response?.statusCode ?? ServerConstants.HttpConstants.serverError
        guard statusCode == ServerConstants.HttpConstants.ok else {
            throw Playback2026ArchetypeError.requestFailed(statusCode: statusCode)
        }
        let archetype = try Api_Playback2026ArchetypeResponse(serializedBytes: data ?? Data()).archetype
        switch archetype {
        case .flaneur: return .flaneur
        case .avantGardist: return .avantGardist
        case .collector: return .collector
        case .aficionado: return .aficionado
        case .anthologist: return .anthologist
        case .unspecified, .UNRECOGNIZED:
            throw Playback2026ArchetypeError.unknownArchetype(rawValue: archetype.rawValue)
        }
    }
}
