import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
#if !os(tvOS)
import Sentry
#endif

enum TranscriptError: Error {
    case notAvailable
    case failedToLoad
    case notSupported(format: String)
    case failedToParse
    case empty

    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return L10n.transcriptErrorNotAvailable
        case .failedToLoad:
            return L10n.transcriptErrorFailedToLoad
        case .notSupported(let format):
            return L10n.transcriptErrorNotSupported(format)
        case .failedToParse:
            return L10n.transcriptErrorFailedToParse
        case .empty:
            return L10n.transcriptErrorEmpty
        }
    }
}

enum OnDemandTranscriptEligibility {
    static var isEligible: Bool {
        isEligible(
            isLoggedIn: SyncManager.isUserLoggedIn(),
            hasActiveSubscription: SubscriptionHelper.hasActiveSubscription(),
            tier: SubscriptionHelper.activeTier,
            flagEnabled: FeatureFlag.onDemandTranscripts.enabled
        )
    }

    static func isEligible(
        isLoggedIn: Bool,
        hasActiveSubscription: Bool,
        tier: SubscriptionTier,
        flagEnabled: Bool
    ) -> Bool {
        guard flagEnabled, isLoggedIn, hasActiveSubscription else {
            return false
        }
        return tier == .plus || tier == .patron
    }
}

enum TranscriptGenerationError: Error {
    case delayed
    case rejected(OnDemandTranscriptResponse.Reason)
    case transient
}

struct TranscriptForegroundPollingBudget {
    let duration: TimeInterval
    private(set) var consumed: TimeInterval = 0

    var remaining: TimeInterval {
        max(0, duration - consumed)
    }

    mutating func consume(from startDate: Date, to endDate: Date) {
        consumed = min(duration, consumed + max(0, endDate.timeIntervalSince(startDate)))
    }
}

class TranscriptManager {
    static let defaultPollingInterval: TimeInterval = 15
    static let defaultPollingTimeout: TimeInterval = 5 * 60

    typealias Transcript = Episode.Metadata.Transcript

    let episodeUUID: String

    let podcastUUID: String

    let showCoordinator: ShowInfoCoordinating
    private let onDemandService: OnDemandTranscriptRequesting
    private let pollingInterval: TimeInterval
    private var pollingBudget: TranscriptForegroundPollingBudget
    private let isEligibleForOnDemand: @Sendable () -> Bool
    private var acceptedOnDemandResponse: OnDemandTranscriptResponse?
    private(set) var onDemandRequestAcceptedAt: Date?

    var hasAcceptedOnDemandRequest: Bool {
        acceptedOnDemandResponse != nil
    }

    private(set) var hasGeneratedTranscripts: Bool = false
    private(set) var isDisplayingGeneratedTranscript: Bool = false

    init(
        episodeUUID: String,
        podcastUUID: String,
        showCoordinator: ShowInfoCoordinating = ShowInfoCoordinator.shared,
        onDemandService: OnDemandTranscriptRequesting = OnDemandTranscriptService.shared,
        pollingInterval: TimeInterval = TranscriptManager.defaultPollingInterval,
        pollingTimeout: TimeInterval = TranscriptManager.defaultPollingTimeout,
        isEligibleForOnDemand: @escaping @Sendable () -> Bool = { OnDemandTranscriptEligibility.isEligible }
    ) {
        self.episodeUUID = episodeUUID
        self.podcastUUID = podcastUUID
        self.showCoordinator = showCoordinator
        self.onDemandService = onDemandService
        self.pollingInterval = pollingInterval
        self.pollingBudget = TranscriptForegroundPollingBudget(duration: pollingTimeout)
        self.isEligibleForOnDemand = isEligibleForOnDemand
    }

    public func loadTranscript() async throws -> TranscriptModel {
        guard
            let metadata = try? await showCoordinator.loadTranscriptsMetadata(podcastUuid: podcastUUID, episodeUuid: episodeUUID),
            !metadata.transcripts.isEmpty else {
            throw TranscriptError.notAvailable
        }
        var transcriptsAvailable = metadata.transcripts
        hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
        isDisplayingGeneratedTranscript = metadata.isDisplayingGeneratedTranscript
        while let transcript = TranscriptFormat.bestTranscript(from: transcriptsAvailable) {
            do {
                let model = try await loadTranscript(transcript)
                return model
            } catch TranscriptError.empty, TranscriptError.failedToParse {
                transcriptsAvailable.removeAll { other in
                    other.transcriptFormat == transcript.transcriptFormat
                }
            } catch {
                throw error
            }
        }
        throw TranscriptError.failedToLoad
    }

    func requestOnDemandTranscript() async throws -> OnDemandTranscriptResponse {
        guard isEligibleForOnDemand() else {
            throw TranscriptGenerationError.rejected(.transcriptIneligible)
        }
        if let acceptedOnDemandResponse {
            return acceptedOnDemandResponse
        }

        do {
            let response = try await onDemandService.requestTranscript(podcastUUID: podcastUUID, episodeUUID: episodeUUID)
            switch response.outcome {
            case .queued, .inProgress, .available:
                acceptedOnDemandResponse = response
                onDemandRequestAcceptedAt = Date()
                return response
            case .notEligible:
                throw TranscriptGenerationError.rejected(response.reason)
            case .transientFailure, .throttled, .unspecified:
                throw TranscriptGenerationError.transient
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as TranscriptGenerationError {
            throw error
        } catch {
            throw TranscriptGenerationError.transient
        }
    }

    func waitForGeneratedTranscript() async throws {
        let pollingStartedAt = Date()
        let deadline = pollingStartedAt.addingTimeInterval(pollingBudget.remaining)
        defer {
            pollingBudget.consume(from: pollingStartedAt, to: Date())
        }

        while Date() < deadline {
            try Task.checkCancellation()
            let metadata = try await showCoordinator.refreshTranscriptsMetadata(
                podcastUuid: podcastUUID,
                episodeUuid: episodeUUID
            )
            if !metadata.transcripts.isEmpty {
                hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
                isDisplayingGeneratedTranscript = metadata.isDisplayingGeneratedTranscript
                return
            }
            let sleepDuration = min(pollingInterval, max(0, deadline.timeIntervalSinceNow))
            guard sleepDuration > 0 else { break }
            try await Task.sleep(nanoseconds: UInt64(sleepDuration * 1_000_000_000))
        }
        throw TranscriptGenerationError.delayed
    }

    private func loadTranscript(_ transcript: Transcript) async throws -> TranscriptModel {
        guard let transcriptFormat = transcript.transcriptFormat else {
            throw TranscriptError.notSupported(format: transcript.type)
        }

        guard
            let transcriptURL = URL(string: transcript.url),
            let transcriptText = try? await dataRetriever.loadTranscript(url: transcriptURL)
        else {
            throw TranscriptError.failedToLoad
        }

        #if !os(tvOS)
        await MainActor.run {
            let crumb = Breadcrumb()
            crumb.level = SentryLevel.info
            crumb.category = "transcript"
            crumb.message = "Transcript file \(transcriptURL)"
            SentrySDK.addBreadcrumb(crumb)
        }
        #endif
        guard let model = TranscriptModel.makeModel(from: transcriptText, format: transcriptFormat) else {
            throw TranscriptError.failedToParse
        }

        if model.isEmtpy {
            throw TranscriptError.empty
        }

        return model
    }

    private lazy var dataRetriever: TranscriptsDataRetriever = {
        return TranscriptsDataRetriever()
    }()
}
