
import UIKit

class WhatsNewHelper: NSObject {
    class func extractWhatsNewInfo() -> WhatsNewInfo? {
        if let filepath = Bundle.main.path(forResource: "aboutWhatsNew", ofType: "json") {
            do {
                let whatsNewInfo = try JSONDecoder().decode(WhatsNewInfo.self, from: Data(contentsOf: URL(fileURLWithPath: filepath)))
                return whatsNewInfo
            } catch {}
        }
        return nil
    }
}
