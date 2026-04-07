import PocketCastsUtils
import UIKit
class JsonUtil {
    class func convert(jsonDate: Any?) -> Date? {
        guard let date = jsonDate as? String else { return nil }

        return DateFormatHelper.sharedHelper.jsonDate(date)
    }
}
