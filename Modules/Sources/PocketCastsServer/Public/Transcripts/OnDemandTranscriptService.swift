import Foundation
import SwiftProtobuf

public protocol OnDemandTranscriptRequesting: Sendable {
    func requestTranscript(podcastUUID: String, episodeUUID: String) async throws -> OnDemandTranscriptResponse
}

public struct OnDemandTranscriptResponse: Equatable, Sendable {
    public enum Outcome: String, Sendable {
        case queued
        case inProgress
        case available
        case notEligible
        case transientFailure
        case throttled
        case unspecified
    }

    public enum Reason: String, Sendable {
        case featureDisabled
        case podcastNotFound
        case episodeNotFound
        case episodeNotInPodcast
        case podcastDisabled
        case podcastDisallowed
        case hostIgnored
        case transcriptIneligible
        case queueingFailed
        case retryNotAvailable
        case internalError
        case unknown
        case unspecified
    }

    public enum Enablement: String, Sendable {
        case enabled
        case alreadyEnabled
        case alreadyEligible
        case notEnabled
        case unspecified
    }

    public let outcome: Outcome
    public let reason: Reason
    public let enablement: Enablement
    public let newlyQueuedCount: UInt32

    public init(outcome: Outcome, reason: Reason, enablement: Enablement, newlyQueuedCount: UInt32) {
        self.outcome = outcome
        self.reason = reason
        self.enablement = enablement
        self.newlyQueuedCount = newlyQueuedCount
    }
}

public enum OnDemandTranscriptServiceError: Error, Equatable {
    case malformedRequest
    case unauthenticated
    case accessDenied
    case notFound
    case transient
    case invalidResponse
    case unexpectedStatus(Int)
}

public final class OnDemandTranscriptService: OnDemandTranscriptRequesting, @unchecked Sendable {
    public static let shared = OnDemandTranscriptService()

    private let tokenHelper: TokenHelper

    public convenience init() {
        self.init(tokenHelper: TokenHelper.shared)
    }

    init(tokenHelper: TokenHelper) {
        self.tokenHelper = tokenHelper
    }

    public func requestTranscript(podcastUUID: String, episodeUUID: String) async throws -> OnDemandTranscriptResponse {
        var body = Api_OnDemandTranscriptRequest()
        body.podcastUuid = podcastUUID
        body.episodeUuid = episodeUUID

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/transcript/on_demand")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.httpBody = try body.serializedData()
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")

        let (response, data) = try await tokenHelper.callSecureUrl(request: request)
        guard let statusCode = response?.statusCode else {
            throw OnDemandTranscriptServiceError.transient
        }

        switch statusCode {
        case ServerConstants.HttpConstants.ok:
            guard let data else {
                throw OnDemandTranscriptServiceError.invalidResponse
            }
            return try map(Api_OnDemandTranscriptResponse(serializedBytes: data))
        case ServerConstants.HttpConstants.badRequest:
            throw OnDemandTranscriptServiceError.malformedRequest
        case ServerConstants.HttpConstants.unauthorized:
            throw OnDemandTranscriptServiceError.unauthenticated
        case 403:
            throw OnDemandTranscriptServiceError.accessDenied
        case ServerConstants.HttpConstants.notFound:
            throw OnDemandTranscriptServiceError.notFound
        case 503:
            throw OnDemandTranscriptServiceError.transient
        default:
            throw OnDemandTranscriptServiceError.unexpectedStatus(statusCode)
        }
    }

    private func map(_ response: Api_OnDemandTranscriptResponse) throws -> OnDemandTranscriptResponse {
        let outcome: OnDemandTranscriptResponse.Outcome = switch response.outcome {
        case .queued: .queued
        case .inProgress: .inProgress
        case .available: .available
        case .notEligible: .notEligible
        case .transientFailure: .transientFailure
        case .throttled: .throttled
        case .outcomeUnspecified, .UNRECOGNIZED: .unspecified
        }

        let reason: OnDemandTranscriptResponse.Reason = switch response.reason {
        case .featureDisabled: .featureDisabled
        case .podcastNotFound: .podcastNotFound
        case .episodeNotFound: .episodeNotFound
        case .episodeNotInPodcast: .episodeNotInPodcast
        case .podcastDisabled: .podcastDisabled
        case .podcastDisallowed: .podcastDisallowed
        case .hostIgnored: .hostIgnored
        case .transcriptIneligible: .transcriptIneligible
        case .queueingFailed: .queueingFailed
        case .retryNotAvailable: .retryNotAvailable
        case .internalError: .internalError
        case .unknownReason: .unknown
        case .reasonUnspecified, .UNRECOGNIZED: .unspecified
        }

        let enablement: OnDemandTranscriptResponse.Enablement = switch response.enablement {
        case .enabled: .enabled
        case .alreadyEnabled: .alreadyEnabled
        case .alreadyEligible: .alreadyEligible
        case .notEnabled: .notEnabled
        case .enablementUnspecified, .UNRECOGNIZED: .unspecified
        }

        return OnDemandTranscriptResponse(
            outcome: outcome,
            reason: reason,
            enablement: enablement,
            newlyQueuedCount: response.newlyQueuedCount
        )
    }
}
