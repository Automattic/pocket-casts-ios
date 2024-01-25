import Foundation

public class URLConnection {

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    public func sendSynchronousRequest(with request: URLRequest) throws -> (Data?, URLResponse?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = session.dataTask(with: request) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)
        if let error = error {
            throw error
        }
        return (data, response)
    }
}
