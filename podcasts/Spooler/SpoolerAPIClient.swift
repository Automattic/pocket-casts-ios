import Foundation

// MARK: - Models
enum BriefDuration: String {
    case short
    case medium
    case long
}

struct SpoolerService: Encodable {
    let type: String
    let data: ServiceData?
}

enum ServiceData: Encodable {
    case string(String)
    case array([String])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

struct SpoolerBriefRequest: Encodable {
    let duration: String
    let language: String
    let minimal: Bool
    let services: [SpoolerService]
    let user: SpoolerUser
}

struct SpoolerUser: Encodable {
    let latitude: String
    let longitude: String
}

// MARK: - Response Models
struct SpoolerBriefResponse: Decodable {
    let data: [BriefSegment]
}

struct BriefSegment: Decodable {
    let type: String
    let url: URL
    let duration: Int?
    let date: TimeInterval?
    let data: String?
}

// MARK: - Errors
enum SpoolerError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

// MARK: - API Client
class SpoolerAPIClient {
    private let baseURL = "https://mybrief.api.spooler.fm"
    private let bearerToken = "bG9sb21nd3RmYmJx"

    static let shared = SpoolerAPIClient()
    private init() {}

    func fetchBrief(duration: BriefDuration, location: (latitude: Double, longitude: Double)?, birthday: String?, services: [String]) async throws -> SpoolerBriefResponse {
        var requestServices: [SpoolerService] = []

        // Add news services
        let newsServices = services.filter { $0.contains("News") }
        requestServices.append(contentsOf: newsServices.map {
            SpoolerService(type: "news", data: .string($0))
        })

        // Add stocks services
        let stockServices = services.filter { $0.contains("Stock") }
        requestServices.append(SpoolerService(type: "stocks", data: .array(stockServices)))

        // Add sports services
        let sportsServices = services.filter { $0.contains("Sports") }
        requestServices.append(contentsOf: sportsServices.map {
            SpoolerService(type: "sports", data: .string($0))
        })

        // Add newsletter services
        let newsletterServices = services.filter { $0.contains("Newsletter") }
        requestServices.append(contentsOf: newsletterServices.map {
            SpoolerService(type: "newsletters", data: .string($0.lowercased().replacingOccurrences(of: " ", with: "")))
        })

        // Add other services (weather, locations, etc)
        let otherServices = services.filter {
            !$0.contains("News") &&
            !$0.contains("Stock") &&
            !$0.contains("Sports") &&
            !$0.contains("Newsletter")
        }
        requestServices.append(contentsOf: otherServices.map {
            SpoolerService(type: $0.lowercased(), data: nil)
        })

        let request = SpoolerBriefRequest(
            duration: duration.rawValue,
            language: "en",
            minimal: false,
            services: requestServices,
            user: SpoolerUser(
                latitude: String(format: "%.5f", location?.latitude ?? 37.7749),
                longitude: String(format: "%.5f", location?.longitude ?? -122.4194)
            )
        )

        let jsonData = try JSONEncoder().encode(request)
        let url = URL(string: "\(baseURL)/v1/brief")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpoolerError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SpoolerBriefResponse.self, from: data)
    }
}
