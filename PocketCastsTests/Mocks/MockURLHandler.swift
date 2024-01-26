import Foundation
import PocketCastsServer

struct MockRequestHandler {
    typealias Handler = ((URLRequest) throws -> (Data, URLResponse?))

    let handler: Handler

    init(handler: @escaping ((URLRequest) throws -> (Data, URLResponse?))) {
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
    convenience init(mockHandler: @escaping MockRequestHandler.Handler) {
        self.init(handler: MockRequestHandler(handler: mockHandler))
    }
}
