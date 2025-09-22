import Foundation
import PocketCastsUtils

public struct BlazePromotion: Decodable {
    public let id: String
    public let text: String
    public let imageURL: URL
    public let urlTitle: String
    public let url: URL
    public let urlAndroid: URL
    public let urlApple: URL
    public let location: Location

    public enum Location: String, Decodable {
        case podcastList = "podcast_list"
        case player
        case unknown

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Location(rawValue: rawValue) ?? .unknown
        }
    }
}

private struct BlazePromotions: Decodable {
    let promotions: [BlazePromotion]
}

extension DiscoverServerHandler {
    func fetchBlazePromotion(for location: BlazePromotion.Location) async -> (promotion: BlazePromotion, useCache: Bool)? {
        let path = ServerConstants.Urls.discover() + "blaze/promotions.json"
        let fetchResult: (BlazePromotion, Bool)? = await withCheckedContinuation { continuation in
            discoverRequest(path: path, type: BlazePromotions.self, authenticated: false) { promotions, useCache in
                if let promotions = promotions,
                   let promotion = promotions.promotions.first(where: { $0.location == location }) {
                    continuation.resume(returning: (promotion, useCache))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        return fetchResult
    }

    func cachedBlazePromotion(for location: BlazePromotion.Location) -> BlazePromotion? {
        let path = ServerConstants.Urls.discover() + "blaze/promotions.json"
        guard let response = cachedResponse(for: path) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let decoded = try decoder.decode(BlazePromotions.self, from: response.data)
            return decoded.promotions.first(where: { $0.location == location })
        } catch {
            FileLog.shared.addMessage("DiscoverServerHandler: Could not decode cached Blaze promotions: \(error)")
            return nil
        }
    }

    public func blazePromotion(for location: BlazePromotion.Location, completion: @escaping (BlazePromotion, Bool) -> Void) {
        if let cachedPromotion = cachedBlazePromotion(for: location) {
            completion(cachedPromotion, false)
            return
        }

        Task {
            if let result = await fetchBlazePromotion(for: location) {
                await MainActor.run {
                    completion(result.promotion, !result.useCache)
                }
            }
        }
    }
}
