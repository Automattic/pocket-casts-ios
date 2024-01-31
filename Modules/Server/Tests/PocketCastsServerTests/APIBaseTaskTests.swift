@testable import PocketCastsServer
import XCTest

final class APIBaseTaskTests: XCTestCase {

    func testGetRequest() {

        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
            return (nil, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        })

        let (_, response) = task.getToServer(url: "http://pocketcasts.com", token: "")

        XCTAssertEqual(response?.statusCode, 200)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    func testGetHeadersRequest() {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Test"), "TestValue")
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
            return (nil, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        })

        let (_, response) = task.getToServer(url: "http://pocketcasts.com", token: "", customHeaders: ["Test": "TestValue"])

        XCTAssertEqual(response?.statusCode, 200)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    func testPostRequest() {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.httpMethod, "POST")
            expectation.fulfill()
            return (nil, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        })

        let (_, statusCode) = task.postToServer(url: "http://pocketcasts.com", token: "", data: Data())

        XCTAssertEqual(statusCode, 200)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    func testEmptyResponsePostRequest() {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.httpMethod, "POST")
            expectation.fulfill()
            return (nil, nil)
        })

        let (data, statusCode) = task.postToServer(url: "http://pocketcasts.com", token: "", data: Data())

        XCTAssertNil(data)
        XCTAssertEqual(statusCode, 500)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    func testDeleteRequest() {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.httpMethod, "DELETE")
            expectation.fulfill()
            return (nil, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        })

        let (_, statusCode) = task.deleteToServer(url: "http://pocketcasts.com", token: "", data: Data())

        XCTAssertEqual(statusCode, 200)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    func testEmptyResponseDeleteRequest() {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, URLResponse?) in
            XCTAssertEqual(request.httpMethod, "DELETE")
            expectation.fulfill()
            return (nil, nil)
        })

        let (data, statusCode) = task.deleteToServer(url: "http://pocketcasts.com", token: nil, data: Data())

        XCTAssertNil(data)
        XCTAssertEqual(statusCode, 500)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)
    }

    // MARK: Generic Request tests
    
    /// Mocks requests for testing with standard checks for HTTPMethod and expectation to wait on response from callbacks.
    /// - Parameters:
    ///   - httpMethod: The httpMethod to send
    ///   - handler: An optional handler to produce a Data and HTTPURLResponse for a given URLRequest
    /// - Returns: Data and HTTPURLResponse
    private func genericRequest(httpMethod: HTTPMethod, handler: ((URLRequest) -> (Data?, HTTPURLResponse?))? = nil) -> (Data?, HTTPURLResponse?) {
        let expectation = self.expectation(description: "APIBaseTask should complete")
        let task = ApiBaseTask(urlConnection: URLConnection { request -> (Data?, HTTPURLResponse?) in
            XCTAssertEqual(request.httpMethod, httpMethod.rawValue)
            expectation.fulfill()
            if let response = handler?(request) {
                return response
            } else {
                return (nil, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
            }
        })

        let url = URL(string: "http://pocketcasts.com")!
        let (data, response) = task.requestToServer(url: url, method: httpMethod, token: nil, retryOnUnauthorized: false, customHeaders: nil, data: nil)

        OperationQueue.main.addOperation(task)
        self.waitForExpectations(timeout: 5)

        return (data, response)
    }

    func testGenericGetRequest() {
        let (data, response) = genericRequest(httpMethod: .get)

        XCTAssertNil(data)
        XCTAssertEqual(response?.statusCode, 200)
    }

    func testGenericPostRequest() {
        let (data, response) = genericRequest(httpMethod: .post)

        XCTAssertNil(data)
        XCTAssertEqual(response?.statusCode, 200)
    }

    func testGenericEmptyResponsePostRequest() {
        let (data, response) = genericRequest(httpMethod: .post) { _ in
            return (nil, nil)
        }

        XCTAssertNil(data)
        XCTAssertEqual(response?.statusCode, 500)
    }

    func testGenericDeleteRequest() {
        let (data, response) = genericRequest(httpMethod: .delete)

        XCTAssertNil(data)
        XCTAssertEqual(response?.statusCode, 200)
    }

    func testGenericEmptyResponseDeleteRequest() {
        let (data, response) = genericRequest(httpMethod: .delete) { _ in
            return (nil, nil)
        }

        XCTAssertNil(data)
        XCTAssertEqual(response?.statusCode, 500)
    }

}
