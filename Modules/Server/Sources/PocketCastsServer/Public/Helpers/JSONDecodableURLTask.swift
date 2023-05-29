import Foundation

/// Generic network task to make calling basic JSON endpoints easier
///
/// Usage:
/// let result = try await JSONDecodableURLTask<MyCoolResponse>.get('https://...')
public struct JSONDecodableURLTask<Response: Decodable> {
    let session: URLSession
    let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .defaultDecoder) {
        self.session = session
        self.decoder = decoder
    }

    public func get(urlString: String, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) async throws -> Response? {
        let url = try URL(throwing: urlString)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = cachePolicy

        return try await perform(request: request)
    }

    public func post(urlString: String, body: Any, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) async throws -> Response? {
        let url = try URL(throwing: urlString)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.cachePolicy = cachePolicy
        return try await perform(request: request)
    }

    public func perform(request: URLRequest) async throws -> Response? {
        let (data, _) = try await session.data(for: request)

        return try decoder.decode(Response.self, from: data)
    }
}

private extension JSONDecoder {
    static var defaultDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }
}
