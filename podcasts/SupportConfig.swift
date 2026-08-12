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

        if case .chatbotSupport = type {
            tagList.append("chatbot_support")
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
        Future { promise in
            Task {
                // Either the file contents to show the user, or the UUID of the file queued for upload
                let value = forDisplay
                    ? await FileLog.shared.logFileAsString()
                    : await FileLog.shared.encryptedLogUUID()

                promise(.success(ZDCustomField(.debugLog, value: value)))
            }
        }
        .eraseToAnyPublisher()
    }

    private func watchLog(forDisplay: Bool) -> AnyPublisher<ZDCustomField, Never> {
        Future { promise in
            Task {
                // Either the file contents to show the user, or the UUID of the file queued for upload
                let value: String
                if forDisplay {
                    value = await WatchManager.shared.requestLogFile() ?? "No wearable logs were available. If you use the Watch app, open it and reopen this screen."
                } else {
                    value = await FileLog.shared.encryptedWatchLogUUID()
                }

                promise(.success(ZDCustomField(.wearableLog, value: value)))
            }
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
                return "\(podcastTitle) (\(podcast.uuid)) override global archive? \(podcast.overrideGlobalArchive) with limit \(podcast.autoArchiveEpisodeLimit)"
            }
            .joined(separator: "\n")

        let reduced = String(allPodcasts.prefix(maxCharacterCount))

        return ZDCustomField(.allPodcasts, value: reduced)
    }
}
