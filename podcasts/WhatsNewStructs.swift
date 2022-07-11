import Foundation
struct WhatsNewInfo: Decodable {
    var versionNo: String
    var versionCode: Int
    var minOSVersion: Int
    var pages: [WhatsNewPage]
}

struct WhatsNewPage: Decodable {
    var items: [WhatsNewItem]
}

struct WhatsNewItem: Decodable {
    var type: String
    var text: String?
    var resource: String?
    var url: String?
}
