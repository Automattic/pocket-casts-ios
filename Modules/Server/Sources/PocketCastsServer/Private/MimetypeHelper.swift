import Swime
import Foundation

public struct MimetypeHelper {
    // The max number of bytes required to cover all the mimetypes
    // needed by `Swime`.
    private static let maxFileSize: Int = 4500
    
    public static func contetType(for url: URL) -> String? {
        do {
            guard let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  let fileHandle = FileHandle(forReadingAtPath: url.relativePath),
                  let data = try fileHandle.read(upToCount: min(fileSize, Self.maxFileSize)) else {
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
