@testable import PocketCastsServer
import XCTest

final class Playback2026ArchetypeTaskTests: XCTestCase {
    private func makeTask(statusCode: Int = 200, body: @escaping () throws -> Data? = { nil }, onRequest: @escaping (URLRequest) -> Void = { _ in }) -> Playback2026ArchetypeTask {
        Playback2026ArchetypeTask(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: { request in
            onRequest(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            return (try body(), response)
        })))
    }

    private func response(_ archetype: Api_Playback2026Archetype) throws -> Data {
        var response = Api_Playback2026ArchetypeResponse()
        response.archetype = archetype
        return try response.serializedData()
    }

    func testSendsGetForProtobuf() async throws {
        var captured: URLRequest?
        let task = makeTask(body: { try self.response(.collector) }, onRequest: { captured = $0 })

        _ = try await task.archetype()

        XCTAssertEqual(captured?.url?.absoluteString, ServerConstants.Urls.api() + "user/playback-2026/archetype")
        XCTAssertEqual(captured?.httpMethod, "GET")
        XCTAssertNil(captured?.httpBody)
        XCTAssertEqual(captured?.value(forHTTPHeaderField: ServerConstants.HttpHeaders.contentType), "application/octet-stream")
        XCTAssertEqual(captured?.value(forHTTPHeaderField: ServerConstants.HttpHeaders.accept), "application/octet-stream")
    }

    func testDecodesEveryArchetype() async throws {
        let expected: [(Api_Playback2026Archetype, Playback2026Archetype)] = [
            (.flaneur, .flaneur),
            (.avantGardist, .avantGardist),
            (.collector, .collector),
            (.aficionado, .aficionado),
            (.anthologist, .anthologist),
        ]
        XCTAssertEqual(expected.count, Playback2026Archetype.allCases.count)

        for (wire, archetype) in expected {
            let result = try await makeTask(body: { try self.response(wire) }).archetype()
            XCTAssertEqual(result, archetype)
        }
    }

    func testThrowsWhenTheServerSendsNoArchetype() async {
        // proto3 leaves the default out: an empty body is `PLAYBACK_2026_ARCHETYPE_UNSPECIFIED`.
        await assertThrows(makeTask(body: { Data() })) {
            guard case .unknownArchetype(rawValue: 0) = $0 else { return XCTFail("\($0)") }
        }
        await assertThrows(makeTask(body: { try self.response(.UNRECOGNIZED(6)) })) {
            guard case .unknownArchetype(rawValue: 6) = $0 else { return XCTFail("\($0)") }
        }
    }

    func testThrowsOnAnError() async {
        await assertThrows(makeTask(statusCode: 401)) {
            guard case .requestFailed(statusCode: 401) = $0 else { return XCTFail("\($0)") }
        }
        await assertThrows(makeTask(statusCode: 500)) {
            guard case .requestFailed(statusCode: 500) = $0 else { return XCTFail("\($0)") }
        }
    }

    private func assertThrows(_ task: Playback2026ArchetypeTask, file: StaticString = #filePath, line: UInt = #line, _ check: (Playback2026ArchetypeTask.Playback2026ArchetypeError) -> Void) async {
        do {
            let archetype = try await task.archetype()
            XCTFail("expected an error, got \(archetype)", file: file, line: line)
        } catch let error as Playback2026ArchetypeTask.Playback2026ArchetypeError {
            check(error)
        } catch {
            XCTFail("unexpected error \(error)", file: file, line: line)
        }
    }
}
