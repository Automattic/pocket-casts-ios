import Foundation

extension FileManager {

    func fileSize(of url: URL) -> Int64? {
        guard let attrs = try? self.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64 else {
            return nil
        }
        return fileSize
    }
}
