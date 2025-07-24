import Foundation
import PocketCastsUtils

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

struct BlazePromotions: Decodable {
    let promotions: [BlazePromotion]
}

public class BlazeServerHandler {
    // This singleton isn't used for much now but we may need to set up handling for expiration so I think it could be needed.
    public static let shared: BlazeServerHandler = .init()

    public func blazePromotions() async -> [BlazePromotion]? {
        let path = "blaze/promotions.json"

        let url = ServerHelper.asUrl(ServerConstants.Urls.discover() + path)
        let request = URLRequest(url: url)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let decoder = JSONDecoder()
                let promotions = try decoder.decode(BlazePromotions.self, from: data)
                return promotions.promotions
            } catch let error {
                FileLog.shared.addMessage("Blaze promotions decoder failed: \(error)")
                return nil
            }
        } catch let error {
            FileLog.shared.addMessage("Blaze promotions request failed: \(error)")
            return nil
        }
    }

    public func promotion(for promotion: BlazePromotion.PromotionType) async -> BlazePromotion? {
        await blazePromotions()?.first(where: { $0.promotion == promotion })
    }
}
