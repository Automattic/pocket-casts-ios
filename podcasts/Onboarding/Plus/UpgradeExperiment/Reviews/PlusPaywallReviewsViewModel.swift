import Foundation

class PlusPaywallReviewsViewModel: ObservableObject {
    var appStoreInfo: AppStoreInfo?

    func parseAppStoreReview() {
        guard let filepath = Bundle.main.path(forResource: "appStoreInfo", ofType: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filepath))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            appStoreInfo = try decoder.decode(AppStoreInfo.self, from: data)
        } catch { }
    }
}
