import Swime
import Foundation

public struct MimetypeHelper {
    public static func contetType(for url: URL) -> String? {
        do {
            guard let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  let fileHandle = FileHandle(forReadingAtPath: url.relativePath),
                  let data = try fileHandle.read(upToCount: min(fileSize, 4500)) else {
                return nil
            }
            let mimeType = Swime.mimeType(data: data)
            fileHandle.closeFile()
            return mimeType?.mime ?? "application/octet-stream"
        } catch {
            return nil
        }
    }
}
