import Foundation
import XCTest
@testable import podcasts

final class SupportConfigTests: XCTestCase {
    func testSupportRequestsGoToTheSupportAddress() {
        XCTAssertEqual(SupportConfig(type: .support).recipient, "support@pocketcasts.com")
        XCTAssertEqual(SupportConfig(type: .feedback).recipient, "support@pocketcasts.com")
        XCTAssertEqual(SupportConfig(type: .satisfactionSurvey).recipient, "support@pocketcasts.com")
    }

    func testChatbotSupportGoesToTheChatbotAddress() {
        XCTAssertEqual(SupportConfig(type: .chatbotSupport).recipient, "chatbot-support@pocketcasts.com")
    }

    func testSubjectNamesTheRequestTypeAndAppVersion() {
        XCTAssertTrue(SupportConfig(type: .support).subject.hasPrefix("iOS Support v\(Settings.appVersion())"))
        XCTAssertTrue(SupportConfig(type: .feedback).subject.hasPrefix("iOS Feedback v\(Settings.appVersion())"))
        XCTAssertTrue(SupportConfig(type: .satisfactionSurvey).subject.hasPrefix("iOS Feedback v\(Settings.appVersion())"))
    }

    func testBodyLeavesRoomForTheMessageAndListsDeviceDetails() {
        let body = SupportConfig(type: .support).body(optOut: false)

        XCTAssertTrue(body.hasPrefix("\n\n\n----------\n\(L10n.supportEmailDetailsPrompt)"))
        XCTAssertTrue(body.contains("App Version: \(Settings.appVersion())"))
        XCTAssertTrue(body.contains("\nTags: platform_ios, app_version_\(Settings.appVersion()), pocket_casts\n"))
    }

    func testTagsStartOnTheirOwnLineWhetherOrNotTheUserOptedOut() {
        for optOut in [true, false] {
            let body = SupportConfig(type: .support).body(optOut: optOut)
            let tagsLine = body.components(separatedBy: "\n").first { $0.contains("Tags: ") }
            XCTAssertEqual(tagsLine?.hasPrefix("Tags: "), true, "optOut: \(optOut)")
        }
    }

    func testBodyListsUploadedLogs() {
        let body = SupportConfig(type: .support).body(optOut: false, logReferences: ["Debug Log: ABC-123", "Watch Log: DEF-456"])

        XCTAssertTrue(body.contains("Debug Log: ABC-123\nWatch Log: DEF-456\n"))
    }

    func testBodyTagsChatbotAndSurveyRequests() {
        XCTAssertTrue(SupportConfig(type: .chatbotSupport).body(optOut: true).contains("chatbot_support"))
        XCTAssertTrue(SupportConfig(type: .satisfactionSurvey).body(optOut: true).contains("satisfaction_survey"))
    }

    func testAttachmentsIncludeTheDebugLog() async {
        let attachments = await SupportConfig(type: .support).attachments()
        let debugLog = attachments.first { $0.fileName == "debug.txt" }

        XCTAssertNotNil(debugLog)
        let contents = debugLog.flatMap { String(data: $0.data, encoding: .utf8) } ?? ""
        XCTAssertTrue(contents.hasPrefix("App Version: \(Settings.appVersion())"))
        XCTAssertTrue(contents.contains("\nTags: platform_ios, app_version_\(Settings.appVersion()), pocket_casts"))
        XCTAssertTrue(contents.contains("Debug Log:"))
    }
}
