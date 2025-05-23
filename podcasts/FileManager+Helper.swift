import Foundation

extension FileManager {

    func fileSize(of url: URL) -> Int64? {

        guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return nil
        }
        return Int64(fileSize)
    }

    static var deviceRemainingFreeSpaceInBytes: Int64? {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            return nil
        }
    }

    static var deviceTotalSpaceInBytes: Int64? {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            return Int64(values.volumeTotalCapacity ?? 0)
        } catch {
            return nil
        }
    }

    static var devicePercentageFreeSpace: Double? {
        guard let total = deviceTotalSpaceInBytes,
              let free = deviceRemainingFreeSpaceInBytes else {
            return nil
        }
        return Double(free) / Double(total)
    }
}
