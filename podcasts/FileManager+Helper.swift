import Foundation

extension FileManager {

    func fileSize(of url: URL) -> Int64? {

        guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return nil
        }
        return Int64(fileSize)
    }
}
