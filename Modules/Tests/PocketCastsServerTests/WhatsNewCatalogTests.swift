import Foundation
@testable import PocketCastsServer
import XCTest

final class WhatsNewCatalogTests: XCTestCase {
    /// A catalog shaped like the published contract, with a message type and an audience this
    /// version of the app doesn't know about.
    private let json = """
    {
      "schemaVersion": 1,
      "generatedAt": "2026-08-17T10:30:00Z",
      "platform": "ios",
      "locale": "en",
      "messages": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440001",
          "type": "new_feature",
          "publishedAt": "2026-08-17T08:00:00Z",
          "expiresAt": "2026-09-17T08:00:00Z",
          "targeting": { "audiences": ["free", "plus", "patron"], "minimumAppVersion": null },
          "title": "Introducing episode transcripts",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/whats-new/media/transcripts-detail.webp",
                "width": 1200,
                "height": 750,
                "alt": "Episode transcript open beside the player"
              },
              "heading": "Read along while you listen",
              "description": "Search a transcript and follow the conversation."
            },
            {
              "image": {
                "url": "https://static.pocketcasts.com/whats-new/media/transcripts-button.webp",
                "width": 1200,
                "height": 750,
                "alt": "The transcript button on an episode"
              },
              "heading": "Try it in any supported episode",
              "description": "Open an episode with a transcript and choose the transcript view.",
              "action": { "event": "open_podcasts", "label": "Try transcripts" }
            }
          ]
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440003",
          "type": "research",
          "publishedAt": "2026-08-12T09:00:00Z",
          "targeting": { "audiences": ["free", "future_audience"] },
          "title": "Help shape the player",
          "description": "Which improvement would make the biggest difference?",
          "poll": {
            "pollId": "550e8400-e29b-41d4-a716-446655440101",
            "pollKey": "player_improvements_2026",
            "question": "What should we improve next?",
            "options": [
              { "id": "550e8400-e29b-41d4-a716-446655440201", "pollOptionKey": "up_next_controls", "label": "Up Next controls" },
              { "id": "550e8400-e29b-41d4-a716-446655440202", "pollOptionKey": "podcast_discovery", "label": "Podcast discovery" }
            ]
          }
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440004",
          "type": "future_type",
          "publishedAt": "2026-08-14T08:00:00Z",
          "targeting": { "audiences": ["plus"] },
          "title": "Something new",
          "pages": []
        }
      ]
    }
    """

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testDecodesMessagesAndDropsUnknownTypes() throws {
        let catalog = try decodedCatalog()

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.locale, "en")
        XCTAssertEqual(catalog.messages.map(\.id),
                       ["550e8400-e29b-41d4-a716-446655440001", "550e8400-e29b-41d4-a716-446655440003"],
                       "The unsupported message type is dropped rather than failing the whole feed")

        let message = try XCTUnwrap(catalog.messages.first)
        XCTAssertEqual(message.type, .newFeature)
        XCTAssertEqual(message.title, "Introducing episode transcripts")
        XCTAssertEqual(message.publishedAt, ISO8601DateFormatter().date(from: "2026-08-17T08:00:00Z"))
        XCTAssertEqual(message.expiresAt, ISO8601DateFormatter().date(from: "2026-09-17T08:00:00Z"))
        XCTAssertEqual(message.targeting.audiences, [.free, .plus, .patron])
        XCTAssertNil(message.targeting.minimumAppVersion)
        XCTAssertEqual(message.content.pages.count, 2)
    }

    func testDecodesTheFieldsOfAPage() throws {
        let pages = try XCTUnwrap(decodedCatalog().messages.first?.content.pages)

        XCTAssertEqual(pages[0].image.url, URL(string: "https://static.pocketcasts.com/whats-new/media/transcripts-detail.webp"))
        XCTAssertEqual(pages[0].image.width, 1200)
        XCTAssertEqual(pages[0].image.height, 750)
        XCTAssertEqual(pages[0].image.alt, "Episode transcript open beside the player")
        XCTAssertEqual(pages[0].image.aspectRatio, 1.6, accuracy: 0.001)
        XCTAssertEqual(pages[0].heading, "Read along while you listen")
        XCTAssertEqual(pages[0].description, "Search a transcript and follow the conversation.")
        XCTAssertNil(pages[0].action, "A page without an action carries none")

        XCTAssertEqual(pages[1].action?.event, "open_podcasts")
        XCTAssertEqual(pages[1].action?.label, "Try transcripts")
    }

    func testDecodesAResearchPoll() throws {
        let message = try XCTUnwrap(decodedCatalog().messages.last)
        let research = try XCTUnwrap(message.content.research)

        XCTAssertTrue(message.content.pages.isEmpty, "A research message has no pages")
        XCTAssertEqual(research.description, "Which improvement would make the biggest difference?")
        XCTAssertEqual(research.poll.pollId, "550e8400-e29b-41d4-a716-446655440101")
        XCTAssertEqual(research.poll.pollKey, "player_improvements_2026")
        XCTAssertEqual(research.poll.question, "What should we improve next?")
        XCTAssertEqual(research.poll.options.map(\.id),
                       ["550e8400-e29b-41d4-a716-446655440201", "550e8400-e29b-41d4-a716-446655440202"],
                       "The options keep the order they were published in")
        XCTAssertEqual(research.poll.options.map(\.pollOptionKey), ["up_next_controls", "podcast_discovery"])
        XCTAssertEqual(research.poll.options.map(\.label), ["Up Next controls", "Podcast discovery"])
    }

    /// A message is all or nothing: it isn't drawn from the pages that happen to be valid.
    func testAMessageWithOneInvalidPageIsDroppedWhole() throws {
        let messages = try decodedMessages(pages: """
        [
          {
            "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
            "heading": "This page is fine",
            "description": "…"
          },
          {
            "image": { "url": "https://static.pocketcasts.com/b.webp", "width": 1200, "height": 750, "alt": "…" },
            "description": "This one has no heading"
          }
        ]
        """)

        XCTAssertTrue(messages.isEmpty)
    }

    func testAMessageWithNoPagesIsDropped() throws {
        XCTAssertTrue(try decodedMessages(pages: "[]").isEmpty)
    }

    func testAPageMissingItsImageIsDropped() throws {
        let messages = try decodedMessages(pages: """
        [{ "heading": "Nothing to show", "description": "…" }]
        """)

        XCTAssertTrue(messages.isEmpty)
    }

    func testAnImageWithNoSizeIsDropped() throws {
        let messages = try decodedMessages(pages: """
        [
          {
            "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 0, "height": 0, "alt": "…" },
            "heading": "Nothing to show",
            "description": "…"
          }
        ]
        """)

        XCTAssertTrue(messages.isEmpty)
    }

    /// Every field the contract requires has to say something, and an empty string doesn't.
    func testARequiredFieldThatSaysNothingDropsTheMessage() throws {
        let messages = try decodedMessages(pages: """
        [
          {
            "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
            "heading": "  ",
            "description": "…"
          }
        ]
        """)

        XCTAssertTrue(messages.isEmpty)
    }

    /// An action is optional, but one that's published has to be complete: an event that names
    /// nothing is a button with nowhere to go.
    func testAnIncompleteActionDropsTheMessage() throws {
        let messages = try decodedMessages(pages: """
        [
          {
            "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
            "heading": "Try transcripts",
            "description": "…",
            "action": { "event": "", "label": "Try transcripts" }
          }
        ]
        """)

        XCTAssertTrue(messages.isEmpty)
    }

    /// The event is free text every client maps for itself, so an unrecognised one decodes fine and
    /// is dropped where the app knows what it does and doesn't implement.
    func testAnActionNamingAnUnknownEventStillDecodes() throws {
        let messages = try decodedMessages(pages: """
        [
          {
            "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
            "heading": "Try transcripts",
            "description": "…",
            "action": { "event": "open_something_from_a_later_release", "label": "Try transcripts" }
          }
        ]
        """)

        XCTAssertEqual(messages.first?.content.pages.first?.action?.event, "open_something_from_a_later_release")
    }

    func testAResearchMessageWithNothingToAnswerIsDropped() throws {
        let json = """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "550e8400-e29b-41d4-a716-446655440003",
              "type": "research",
              "publishedAt": "2026-08-12T09:00:00Z",
              "targeting": {},
              "title": "Help shape the player",
              "poll": {
                "pollId": "550e8400-e29b-41d4-a716-446655440101",
                "pollKey": "player_improvements_2026",
                "question": "What should we improve next?",
                "options": []
              }
            }
          ]
        }
        """

        let catalog = try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))

        XCTAssertTrue(catalog.messages.isEmpty)
    }

    /// The types share their page shape today, but each declares its own contract: a standard
    /// message's pages don't make a research message, and a poll doesn't make a tip.
    func testAMessageCarryingTheOtherTypesContentIsDropped() throws {
        let json = """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "550e8400-e29b-41d4-a716-446655440001",
              "type": "tip",
              "publishedAt": "2026-08-12T09:00:00Z",
              "targeting": {},
              "title": "Sort your Up Next",
              "poll": {
                "pollId": "550e8400-e29b-41d4-a716-446655440101",
                "pollKey": "player_improvements_2026",
                "question": "What should we improve next?",
                "options": [{ "id": "550e8400-e29b-41d4-a716-446655440201", "pollOptionKey": "up_next", "label": "Up Next" }]
              }
            },
            {
              "id": "550e8400-e29b-41d4-a716-446655440003",
              "type": "research",
              "publishedAt": "2026-08-12T09:00:00Z",
              "targeting": {},
              "title": "Help shape the player",
              "pages": [
                {
                  "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
                  "heading": "…",
                  "description": "…"
                }
              ]
            }
          ]
        }
        """

        let catalog = try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))

        XCTAssertTrue(catalog.messages.isEmpty)
    }

    func testDecodesTimestampsWithFractionalSeconds() throws {
        let json = """
        {
          "schemaVersion": 1,
          "generatedAt": "2026-08-17T10:30:00.000Z",
          "messages": [
            {
              "id": "550e8400-e29b-41d4-a716-446655440001",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00.123Z",
              "targeting": {},
              "title": "Sleep timer shortcuts",
              "pages": [
                {
                  "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
                  "heading": "Hold the sleep timer button",
                  "description": "…"
                }
              ]
            }
          ]
        }
        """

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let catalog = try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))

        XCTAssertEqual(catalog.generatedAt, formatter.date(from: "2026-08-17T10:30:00.000Z"))
        XCTAssertEqual(catalog.messages.count, 1, "A timestamp with fractional seconds doesn't drop the message")
        XCTAssertEqual(catalog.messages.first?.publishedAt, formatter.date(from: "2026-08-17T08:00:00.123Z"))
    }

    func testDropsUnknownAudiencesWithoutLosingTheirNeighbours() throws {
        let message = try XCTUnwrap(decodedCatalog().messages.last)

        XCTAssertEqual(message.targeting.rawAudiences, ["free", "future_audience"], "The unsupported audience is kept as published")
        XCTAssertEqual(message.targeting.audiences, [.free], "Only the audiences this version understands are mapped")
    }

    func testAMessageAimedOnlyAtAnUnknownAudienceTargetsNobody() throws {
        let targeting = try decodedTargeting(#"{ "audiences": ["future_tier"] }"#)

        XCTAssertTrue(targeting.audiences.isEmpty)
        XCTAssertFalse(targeting.targets(.free), "An audience this version can't evaluate hides the message")
        XCTAssertFalse(targeting.targets(.plus))
        XCTAssertFalse(targeting.targets(.patron))
    }

    func testAMessageWithNoAudiencesTargetsEveryone() throws {
        let targeting = try decodedTargeting("{}")

        XCTAssertTrue(targeting.rawAudiences.isEmpty)
        XCTAssertTrue(targeting.targets(.free))
        XCTAssertTrue(targeting.targets(.plus))
        XCTAssertTrue(targeting.targets(.patron))
    }

    func testASuccessfulRefreshIsReadableBackFromDisk() async throws {
        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: temporaryCache(), locale: "en")
        XCTAssertNil(task.cachedCatalog())
        XCTAssertNil(task.cachedCatalogDate)

        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
        let fetched = try await task.refresh()

        XCTAssertEqual(task.cachedCatalog()?.messages.map(\.id), fetched.messages.map(\.id))
        XCTAssertEqual(try XCTUnwrap(task.cachedCatalogDate).timeIntervalSinceNow, 0, accuracy: 5,
                       "The cache is dated when it's written, which is what decides the next refresh")
    }

    func testAFailedRefreshLeavesTheCachedCopyAlone() async throws {
        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: temporaryCache(), locale: "en")

        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
        let fetched = try await task.refresh()

        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await task.refresh()
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        XCTAssertEqual(task.cachedCatalog()?.messages.map(\.id), fetched.messages.map(\.id))
    }

    func testRefreshFallsBackToEnglishWhenTheLocaleIsNotPublished() async throws {
        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: temporaryCache(), locale: "pt")

        var requestedPaths: [String] = []
        StubURLProtocol.requestHandler = { [json] request in
            let url = request.url!
            requestedPaths.append(url.lastPathComponent)
            guard url.lastPathComponent == "en.json" else {
                return (HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
            }
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
        }

        let catalog = try await task.refresh()

        XCTAssertEqual(requestedPaths, ["pt.json", "en.json"])
        XCTAssertEqual(catalog.messages.count, 2)
        XCTAssertEqual(task.cachedCatalog()?.messages.count, 2, "The fallback catalog is cached for the requested locale")
    }

    /// The mock is what the previews and the app's own tests are built on, so it has to stay a
    /// catalog the models actually accept.
    func testTheMockCatalogCoversEveryMessageType() {
        let types = Set(WhatsNewCatalog.mock.messages.map(\.type))

        XCTAssertEqual(types, Set(WhatsNewMessageType.allCases))
    }

    // MARK: - Locale

    /// The app names its Chinese and Brazilian localizations one way and the catalog another, so a
    /// reader on one of them would otherwise be handed English.
    func testAnAppLocalizationIsMatchedToThePublishedCatalog() {
        let expected = [
            "en": "en",
            "pt-BR": "pt-br",
            "zh-Hans": "zh-cn",
            "zh-Hant": "zh-tw",
            "zh-Hant-TW": "zh-tw",
            "es-MX": "es",
            "fr-CA": "fr",
            "ca": "ca",
            "pt-PT": "en",
            "ko": "en"
        ]

        for (localization, locale) in expected {
            XCTAssertEqual(WhatsNewCatalogTask.locale(forLocalization: localization), locale, "\(localization) should read the \(locale) catalog")
        }
    }

    // MARK: - Helpers

    private func decodedTargeting(_ json: String) throws -> WhatsNewTargeting {
        try WhatsNewCatalog.decoder.decode(WhatsNewTargeting.self, from: Data(json.utf8))
    }

    private func decodedCatalog() throws -> WhatsNewCatalog {
        try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))
    }

    /// A catalog with one standard message whose pages are whatever the test is about.
    private func decodedMessages(pages: String) throws -> [WhatsNewMessage] {
        let json = """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "550e8400-e29b-41d4-a716-446655440001",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": {},
              "title": "Sort your Up Next",
              "pages": \(pages)
            }
          ]
        }
        """
        return try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8)).messages
    }

    private func temporaryCache() -> WhatsNewCatalogCache {
        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return WhatsNewCatalogCache(directory: directory)
    }
}
