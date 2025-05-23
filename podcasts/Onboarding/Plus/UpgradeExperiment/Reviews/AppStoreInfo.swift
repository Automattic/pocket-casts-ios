import Foundation

struct AppStoreInfo: Codable {
    let rating: String
    let reviewCount: String
    let reviews: [AppStoreReview]
}

struct AppStoreReview: Identifiable, Codable {
    let id: Int
    let title: String
    let review: String
    let date: String

    var formattedDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy-MM-dd"
        return dateFormatter.date(from: date)
    }
}
