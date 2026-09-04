import Foundation
@testable import PocketCastsServer
import XCTest

final class WhatsNewCatalogTests: XCTestCase {
    /// A catalog shaped like the published contract, with a message type, an audience, and a block
    /// that this version of the app doesn't know about.
    private let json = """
    {
      "schemaVersion": 1,
      "generatedAt": "2026-08-17T10:30:00Z",
      "platform": "ios",
      "locale": "en",
      "messages": [
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "new_feature",
          "publishedAt": "2026-08-17T08:00:00Z",
          "expiresAt": "2026-09-17T08:00:00Z",
          "targeting": { "audiences": ["free", "plus", "patron"], "minimumAppVersion": null },
          "summary": {
            "title": "Introducing episode transcripts",
            "label": "New Feature",
            "imageUrl": "https://static.pocketcasts.com/whats-new/media/transcripts-card.webp"
          },
          "content": {
            "title": "Introducing episode transcripts",
            "pages": [
              {
                "blocks": [
                  { "type": "heading", "level": 2, "text": "Read along while you listen" },
                  { "type": "paragraph", "content": "Search a transcript and follow the conversation." },
                  {
                    "type": "image",
                    "url": "https://static.pocketcasts.com/whats-new/media/transcripts-detail.webp",
                    "width": 1200,
                    "height": 750,
                    "alt": "Episode transcript open beside the player"
                  }
                ]
              },
              {
                "blocks": [
                  { "type": "action", "label": "Try transcripts", "url": "pocketcasts://podcasts", "style": "primary" }
                ]
              }
            ]
          }
        },
        {
          "id": "01K2Y2CFD0VAWA4N74D3N6JTVK",
          "type": "research",
          "publishedAt": "2026-08-12T09:00:00Z",
          "targeting": { "audiences": ["free", "future_audience"] },
          "summary": { "title": "Help shape the player" },
          "content": {
            "pages": [
              {
                "blocks": [
                  { "type": "paragraph", "content": "Which improvement would make the biggest difference?" },
                  { "type": "poll", "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT", "question": "What next?", "options": [] },
                  { "type": "paragraph", "content": "The survey takes about two minutes." }
                ]
              }
            ]
          }
        },
        {
          "id": "01K2Y1JQ4T7Z7T5RY8G0QPA3NX",
          "type": "future_type",
          "publishedAt": "2026-08-14T08:00:00Z",
          "targeting": { "audiences": ["plus"] },
          "summary": { "title": "Something new" },
          "content": { "pages": [] }
        }
      ]
    }
    """

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testDecodesMessagesAndDropsUnknownTypes() throws {
        let catalog = try decodedCatalog()

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.locale, "en")
        XCTAssertEqual(catalog.messages.map(\.id),
                       ["01K2Y08DAWG9N7XJZX5QTH9Z0K", "01K2Y2CFD0VAWA4N74D3N6JTVK"],
                       "The unsupported message type is dropped rather than failing the whole feed")

        let message = try XCTUnwrap(catalog.messages.first)
        XCTAssertEqual(message.type, .newFeature)
        XCTAssertEqual(message.summary.title, "Introducing episode transcripts")
        XCTAssertEqual(message.summary.label, "New Feature")
        XCTAssertEqual(message.publishedAt, ISO8601DateFormatter().date(from: "2026-08-17T08:00:00Z"))
        XCTAssertEqual(message.expiresAt, ISO8601DateFormatter().date(from: "2026-09-17T08:00:00Z"))
        XCTAssertEqual(message.targeting.audiences, [.free, .plus, .patron])
        XCTAssertNil(message.targeting.minimumAppVersion)
        XCTAssertEqual(message.content.pages.count, 2)
    }

    func testDecodesSupportedBlocks() throws {
        let pages = try XCTUnwrap(decodedCatalog().messages.first?.content.pages)

        guard case .heading(let heading) = pages[0].blocks[0] else {
            XCTFail("Expected a heading block, got \(pages[0].blocks[0])")
            return
        }
        XCTAssertEqual(heading.level, 2)
        XCTAssertEqual(heading.text, "Read along while you listen")

        guard case .paragraph(let paragraph) = pages[0].blocks[1] else {
            XCTFail("Expected a paragraph block, got \(pages[0].blocks[1])")
            return
        }
        XCTAssertEqual(paragraph.content, "Search a transcript and follow the conversation.")

        guard case .image(let image) = pages[0].blocks[2] else {
            XCTFail("Expected an image block, got \(pages[0].blocks[2])")
            return
        }
        XCTAssertEqual(image.width, 1200)
        XCTAssertEqual(image.height, 750)
        XCTAssertEqual(image.alt, "Episode transcript open beside the player")

        guard case .action(let action) = pages[1].blocks[0] else {
            XCTFail("Expected an action block, got \(pages[1].blocks[0])")
            return
        }
        XCTAssertEqual(action.label, "Try transcripts")
        XCTAssertEqual(action.url, URL(string: "pocketcasts://podcasts"))
        XCTAssertEqual(action.style, .primary)
    }

    func testDropsPagesAndMessagesWithNothingToRender() throws {
        let json = """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "01K2Y2CFD0VAWA4N74D3N6JTVK",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": {},
              "summary": { "title": "One page of its own" },
              "content": {
                "pages": [
                  { "blocks": [{ "type": "poll", "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT" }] },
                  { "blocks": [{ "type": "paragraph", "content": "This page still renders." }] }
                ]
              }
            },
            {
              "id": "01K2Y1JQ4T7Z7T5RY8G0QPA3NX",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": {},
              "summary": { "title": "Nothing to render" },
              "content": { "pages": [{ "blocks": [{ "type": "poll", "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT" }] }] }
            }
          ]
        }
        """

        let catalog = try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))

        XCTAssertEqual(catalog.messages.map(\.id), ["01K2Y2CFD0VAWA4N74D3N6JTVK"],
                       "A message whose pages have nothing renderable is dropped rather than opening onto an empty pager")
        XCTAssertEqual(catalog.messages.first?.content.pages.count, 1,
                       "The page of unknown blocks is dropped, the page beside it is kept")
    }

    func testDropsVideoBlocksWithNoPlayableSources() throws {
        let json = """
        {
          "blocks": [
            { "type": "video", "posterUrl": "https://static.pocketcasts.com/whats-new/media/transcripts-poster.webp" },
            {
              "type": "video",
              "sources": [{ "url": "https://static.pocketcasts.com/whats-new/media/transcripts.mp4", "mimeType": "video/mp4" }],
              "alt": "Scrolling through a transcript"
            }
          ]
        }
        """

        let page = try WhatsNewCatalog.decoder.decode(WhatsNewPage.self, from: Data(json.utf8))

        XCTAssertEqual(page.blocks.count, 1, "The video with no playable sources is dropped")
        guard case .video(let video) = page.blocks[0] else {
            XCTFail("Expected a video block, got \(page.blocks[0])")
            return
        }
        XCTAssertEqual(video.sources.map(\.url), [URL(string: "https://static.pocketcasts.com/whats-new/media/transcripts.mp4")])
        XCTAssertEqual(video.alt, "Scrolling through a transcript")
    }

    func testDecodesTimestampsWithFractionalSeconds() throws {
        let json = """
        {
          "schemaVersion": 1,
          "generatedAt": "2026-08-17T10:30:00.000Z",
          "messages": [
            {
              "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00.123Z",
              "targeting": {},
              "summary": { "title": "Sleep timer shortcuts" },
              "content": { "pages": [{ "blocks": [{ "type": "paragraph", "content": "Hold the sleep timer button." }] }] }
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

    func testDropsUnknownBlocksAndAudiencesWithoutLosingTheirNeighbours() throws {
        let message = try XCTUnwrap(decodedCatalog().messages.last)
        let blocks = try XCTUnwrap(message.content.pages.first?.blocks)

        XCTAssertEqual(blocks.count, 2, "The poll block is dropped, the paragraphs around it are kept")
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

    func testCatalogFallsBackToTheCachedCopyWhenTheRequestFails() async throws {
        let task = WhatsNewCatalogTask(session: stubbedSession(), cache: temporaryCache(), locale: "en")

        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
        let fetched = try await task.catalog()
        XCTAssertEqual(fetched.messages.count, 2)

        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let cached = try await task.catalog()
        XCTAssertEqual(cached.messages.map(\.id), fetched.messages.map(\.id))
    }

    func testRefreshFallsBackToEnglishWhenTheLocaleIsNotPublished() async throws {
        let task = WhatsNewCatalogTask(session: stubbedSession(), cache: temporaryCache(), locale: "pt")

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

    func testCatalogRethrowsCancellationRatherThanReturningTheCachedCopy() async throws {
        let task = WhatsNewCatalogTask(session: stubbedSession(), cache: temporaryCache(), locale: "en")

        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
        _ = try await task.catalog()

        StubURLProtocol.requestHandler = { _ in throw URLError(.cancelled) }

        do {
            _ = try await task.catalog()
            XCTFail("Expected the cancelled request to propagate")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
    }

    func testCatalogThrowsWhenTheRequestFailsAndNothingIsCached() async {
        let task = WhatsNewCatalogTask(session: stubbedSession(), cache: temporaryCache(), locale: "en")

        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await task.catalog()
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    private func decodedTargeting(_ json: String) throws -> WhatsNewTargeting {
        try WhatsNewCatalog.decoder.decode(WhatsNewTargeting.self, from: Data(json.utf8))
    }

    private func decodedCatalog() throws -> WhatsNewCatalog {
        try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))
    }

    private func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func temporaryCache() -> WhatsNewCatalogCache {
        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return WhatsNewCatalogCache(directory: directory)
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
