import Foundation

public struct BlazePromotion: Decodable {
    public let id: String
    public let text: String
    public let imageURL: URL
    public let urlTitle: String
    public let url: URL
    public let promotion: PromotionType

    public enum PromotionType: String, Decodable {
        case podcastList
        case player
        case unknown
    }
}

private struct BlazePromotions: Decodable {
    let promotions: [BlazePromotion]
}

extension DiscoverServerHandler {
    public func blazePromotions() async -> [BlazePromotion]? {
        let path = ServerConstants.Urls.discover() + "blaze/promotions.json"
        let promotions = await withCheckedContinuation { continuation in
            discoverRequest(path: path, type: BlazePromotions.self, authenticated: false) { promotions, useCache in
                if let promotions = promotions {
                    continuation.resume(returning: promotions)
                }
            }
        }

        return promotions.promotions
    }

    public func blazePromotion(for promotion: BlazePromotion.PromotionType) async -> BlazePromotion? {
        await blazePromotions()?.first(where: { $0.promotion == promotion })
    }
}
