import Foundation

/// A generic request handler to send URLRequests with a completion block
public protocol RequestHandler {
    func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: RequestHandler {
    public func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}

public class URLConnection {

    private let handler: RequestHandler

    public init(handler: RequestHandler) {
        self.handler = handler
    }

    public func sendSynchronousRequest(with request: URLRequest) throws -> (Data?, URLResponse?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        handler.send(request: request) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)
        if let error = error {
            throw error
        }
        return (data, response)
    }

    public func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        handler.send(request: request, completion: completion)
    }
}
