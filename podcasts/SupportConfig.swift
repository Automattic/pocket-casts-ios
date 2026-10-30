import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

enum SupportRequestType {
    case feedback
    case satisfactionSurvey
    case support
    case chatbotSupport
}

/// Describes the email a support or feedback request is sent as: who it goes to, its subject,
/// and the device details and logs that go with it.
struct SupportConfig {
    static let supportAddress = "support@pocketcasts.com"
    static let chatbotSupportAddress = "chatbot-support@pocketcasts.com"

    struct Attachment {
        let fileName: String
        let data: Data
    }

    let type: SupportRequestType
    private let maxCharacterCount = 65000

    var recipient: String {
        type == .chatbotSupport ? Self.chatbotSupportAddress : Self.supportAddress
    }

    var isFeedback: Bool {
        switch type {
        case .feedback, .satisfactionSurvey:
            return true
        default:
            return false
        }
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

    /// The device details and tags, as the header of the attached debug log or in the body of an email without attachments.
    private func deviceDetails(optOut: Bool) -> String {
        // DebugInfo ends with a newline only when opted out, so trim it before adding the tags.
        DebugInfo.string(optOut: optOut).trimmingCharacters(in: .newlines) + "\nTags: \(tags.joined(separator: ", "))\n"
    }

    /// The body of an email that can't carry attachments: room for the customer to write, then the device
    /// details and the uploaded logs (`logReferences`) below a divider.
    func body(optOut: Bool, logReferences: [String] = []) -> String {
        var details = deviceDetails(optOut: optOut)
        if !logReferences.isEmpty {
            details += "\n" + logReferences.joined(separator: "\n") + "\n"
        }

        return "\n\n\n----------\n\(L10n.supportEmailDetailsPrompt)\n\n\(details)"
    }

    /// The whole email as text to paste into any email app: address, subject, then the body without its leading blank lines.
    func copyableEmail(body: String) -> String {
        let trimmedBody = String(body.drop(while: \.isNewline))
        return "To: \(recipient)\nSubject: \(subject)\n\n\(trimmedBody)"
    }

    /// A `mailto:` link for an email that can't carry attachments.
    func mailtoURL(body: String) -> URL? {
        // RFC 6068: line breaks must be CRLF, and everything outside the unreserved set is percent-encoded.
        // URLComponents leaves `?`, `=` and `/` alone in query values, which cuts the body short in Gmail.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
        }

        let crlfBody = body.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: "\r\n")
        return URL(string: "mailto:\(recipient)?subject=\(encode(subject))&body=\(encode(crlfBody))")
    }

    /// The files attached to the email: the app's debug log headed by the device details and followed podcasts, and the Apple Watch log when there is one.
    /// A user who opted out of sharing debug information gets only the basic device details, as with the in-app form before.
    func attachments(optOut: Bool) async -> [Attachment] {
        guard !optOut else {
            let details = deviceDetails(optOut: true) + "\nLogs not included: the user opted out of sharing debug information.\n"
            return [Attachment(fileName: "debug.txt", data: Data(details.utf8))]
        }

        let debugLog = """
        \(deviceDetails(optOut: false))
        Podcasts:
        \(allPodcasts)

        Debug Log:
        \(await FileLog.shared.logFileAsString())
        """

        var attachments = [Attachment(fileName: "debug.txt", data: Data(debugLog.utf8))]
        if let watchLog = await FileLog.shared.watchLogFileAsString() {
            attachments.append(Attachment(fileName: "watch-debug.txt", data: Data(watchLog.utf8)))
        }

        return attachments
    }

    /// Uploads the logs as encrypted logs, waiting for each upload to finish, and returns a line for each one:
    /// a link support can open, or a note that it couldn't be uploaded.
    func uploadedLogReferences() async -> [String] {
        var references = [Self.logReference("Debug log", uuid: await FileLog.shared.uploadDebugLog(timeout: Self.logUploadTimeout))]

        if let watchLogPath = try? await FileLog.shared.watchLogFileForUpload() {
            let uuid = await FileLog.shared.uploadLog(atPath: watchLogPath, timeout: Self.logUploadTimeout)
            references.append(Self.logReference("Watch log", uuid: uuid))
        }

        return references
    }

    static let logUploadTimeout: TimeInterval = 15

    static func logReference(_ name: String, uuid: String?) -> String {
        guard let uuid else {
            return "\(name): couldn't be uploaded"
        }
        return "\(name): https://mc.a8c.com/encrypted-logs.php?uuid=\(uuid)"
    }

    private var allPodcasts: String {
        let allPodcasts = DataManager.shared.allPodcastsOrderedByTitle()
            .map { podcast -> String in
                let podcastTitle = podcast.title ?? ""
                return "\(podcastTitle) (\(podcast.uuid)) override global archive? \(podcast.overrideGlobalArchive) with limit \(podcast.autoArchiveEpisodeLimit)"
            }
            .joined(separator: "\n")

        return String(allPodcasts.prefix(maxCharacterCount))
    }
}
