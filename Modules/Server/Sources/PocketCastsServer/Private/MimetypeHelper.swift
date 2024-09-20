import Swime
import Foundation

public struct MimetypeHelper {
    public static func contetType(for url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            let mimeType = Swime.mimeType(data: data)
            return mimeType?.mime ?? "application/octet-stream"
        } catch {
            return nil
        }
    }
}
