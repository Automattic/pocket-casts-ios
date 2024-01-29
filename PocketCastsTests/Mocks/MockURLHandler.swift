import Foundation
import PocketCastsServer

struct MockRequestHandler {
    typealias Handler = ((URLRequest) throws -> (Data?, URLResponse?))

    let handler: Handler

    init(handler: @escaping ((URLRequest) throws -> (Data?, URLResponse?))) {
        self.handler = handler
    }
}

extension MockRequestHandler: RequestHandler {
    func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        do {
            let (data, response) = try handler(request)
            completion(data, response, nil)
        } catch let error {
            completion(nil, nil, error)
        }
    }
}

extension URLConnection {
    /// A convenient initializer to pass a block which returns data, response, and error for a given URLRequest.
    /// - Parameter mockHandler: The handler block (URLRequest) throws -> (Data, URLResponse?)
    convenience init(mockHandler: @escaping MockRequestHandler.Handler) {
        self.init(handler: MockRequestHandler(handler: mockHandler))
    }
}
