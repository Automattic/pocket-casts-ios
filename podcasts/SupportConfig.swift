import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

enum SupportCustomField: Int, CaseIterable {
    case debugLog = 360_049_192_052
    case wearableLog = 360_049_192_072
    case allPodcasts = 360_049_245_291
    case metaData = 360_049_245_311

    var dispalyTitle: String {
        switch self {
        case .debugLog:
            return L10n.supportLogsDebug
        case .wearableLog:
            return L10n.supportLogsWearable
        case .allPodcasts:
            return L10n.supportLogsPodcasts
        case .metaData:
            return L10n.supportLogsMetaData
        }
    }

    var displayOrder: Int {
        switch self {
        case .debugLog:
            return 4
        case .wearableLog:
            return 3
        case .allPodcasts:
            return 2
        case .metaData:
            return 1
        }
    }
}

extension ZDCustomField {
    init(_ field: SupportCustomField, value: String) {
        self.init(id: field.rawValue, value: value)
    }
}

struct SupportConfig: ZDConfig {
    let apiKey = ApiCredentials.zendeskAPIKey
    let baseURL = ApiCredentials.zendeskUrl
    let newBaseURL = ApiCredentials.zendeskNewUrl
    let type: ZDType
    private let maxCharacterCount = 65000
    private let logsOptedOutMessage = "No log file uploaded: User opted out"
    private let optedOutMessage = "User opted out"

    var tags: [String] {
        var tagList = ["platform_ios", "app_version_\(Settings.appVersion())", "pocket_casts"]

        if SubscriptionHelper.hasActiveSubscription() {
            tagList.append("plus")
        }

        if case .satisfactionSurvey = type {
            tagList.append("satisfaction_survey")
        }

        return tagList
    }

    var subject: String {
        let requestType = (isFeedback ? L10n.supportFeedback : L10n.support)
        var subject = "iOS \(requestType) v\(Settings.appVersion())"

        if SubscriptionHelper.hasActiveSubscription() {
            subject += " - Plus Account"
        }

        #if DEBUG
            subject += " - (Testing)"
        #endif

        return subject
    }

    // MARK: Custom Fields

    func customFields(forDisplay: Bool, optOut: Bool) -> AnyPublisher<[ZDCustomField], Never> {
        guard !optOut else {
            return Just([
                appMetaData(optOut: true),
                ZDCustomField(.allPodcasts, value: optedOutMessage),
                ZDCustomField(.wearableLog, value: logsOptedOutMessage),
                ZDCustomField(.debugLog, value: logsOptedOutMessage)
            ]).eraseToAnyPublisher()
        }

        return Publishers.MergeMany(debugLog(forDisplay: forDisplay), watchLog(forDisplay: forDisplay))
            .collect()
            .receive(on: DispatchQueue.global(qos: .background), options: nil)
            .eraseToAnyPublisher()
            .map { asyncFields in
                [appMetaData(optOut: false), allPodcasts] + asyncFields
            }
            .eraseToAnyPublisher()
    }

    private func debugLog(forDisplay: Bool) -> AnyPublisher<ZDCustomField, Never> {
        if forDisplay {
            // Return the File Contents to show the user
            return Future { promise in
                FileLog.shared.loadLogFileAsString(completion: { contents in
                    promise(.success(ZDCustomField(.debugLog, value: contents)))
                })
            }
            .eraseToAnyPublisher()
        }

        // Return the File UUID that has been queued for upload
        return FileLog.shared.encryptedLogUUID()
            .map { uuid in
                ZDCustomField(.debugLog, value: uuid)
            }
            .eraseToAnyPublisher()
    }

    private func watchLog(forDisplay: Bool) -> AnyPublisher<ZDCustomField, Never> {
        if forDisplay {
            // Return the File Contents to show the user
            return Future { promise in
                WatchManager.shared.requestLogFile { watchLog in
                    let wearableLog = watchLog ?? "No wearable logs were available. If you use the Watch app, open it and reopen this screen."
                    promise(.success(ZDCustomField(.wearableLog, value: wearableLog)))
                }
            }
            .eraseToAnyPublisher()
        }

        // Return the File Name to be enqued for upload
        return FileLog.shared.encryptedWatchLogUUID()
            .map { uuid in
                ZDCustomField(.wearableLog, value: uuid)
            }
            .eraseToAnyPublisher()
    }

    private func appMetaData(optOut: Bool) -> ZDCustomField {
        return ZDCustomField(.metaData, value: DebugInfo.string(optOut: optOut))
    }

    private var allPodcasts: ZDCustomField {
        let allPodcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()
            .map { podcast -> String in
                let podcastTitle = podcast.title ?? ""
                return "\(podcastTitle) (\(podcast.uuid)) override global archive? \(podcast.isAutoArchiveOverridden) with limit \(podcast.autoArchiveEpisodeLimitCount)"
            }
            .joined(separator: "\n")

        let reduced = String(allPodcasts.prefix(maxCharacterCount))

        return ZDCustomField(.allPodcasts, value: reduced)
    }
}
