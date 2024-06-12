import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import Combine
import Pulse

class DatabaseExport {
    /// The resulting file name of the zip file
    let exportName: String

    private var cancellables = Set<AnyCancellable>()

    init(exportName: String = "Pocket Casts Export") {
        self.exportName = exportName
    }

    private let fileManager = FileManager.default

    /// Create a zip of the database and prefrences
    func export() async -> URL? {
        guard let exportFolder = await self.prepareFiles() else {
            return nil
        }

        return await withCheckedContinuation { continutation in
            let coordinator = NSFileCoordinator()

            // The file coordinate will zip the export folder for us
            coordinator.coordinate(readingItemAt: exportFolder, options: .forUploading, error: nil) { zipURL in
                do {
                    // The generated zip file is only available until this block exits
                    // so we need to move it to a more permanent location
                    let tempURL = exportFolder.appendingPathComponent("\(self.exportName).zip")
                    try self.fileManager.moveItem(at: zipURL, to: tempURL)

                    continutation.resume(returning: tempURL)
                } catch {
                    FileLog.shared.addMessage("[Export] Could not generate zip file: \(error)")
                    continutation.resume(returning: nil)
                }
            }
        }
    }

    /// Attempt to remove the temporary export directory and files
    func cleanup(url: URL) {
        do {
            try fileManager.removeItem(at: url.deletingLastPathComponent())
        } catch {
            FileLog.shared.addMessage("[Export] Could not cleanup file: \(error)")
        }
    }

    /// Copies the database and preferences to a temporary directory
    private func prepareFiles() async -> URL? {
        do {
            let databaseURL = URL(fileURLWithPath: DataManager.pathToDb())

            // Create a temporary directory to store the files in
            let temporaryDirectory = try fileManager.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: databaseURL,
                                                         create: true)

            let exportDirectory = temporaryDirectory.appendingPathComponent(exportName, isDirectory: true)

            try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

            FileLog.shared.forceFlush()
            let logFile = try await FileLog.shared.logFileForUpload().awaitFirstValue(in: &cancellables)
            let logsFile = exportDirectory.appendingPathComponent("logs.txt", isDirectory: false)
            try fileManager.copyItem(at: URL(fileURLWithPath: logFile), to: logsFile)

            let networkLogsFile = exportDirectory.appendingPathComponent("network.pulse", isDirectory: false)
            try await LoggerStore.shared.export(to: networkLogsFile)

            // Write the bundle document
            let exportFile = exportDirectory.appendingPathComponent("export", conformingTo: .pcasts)
            let wrapper = try PCBundleDoc().fileWrapper()
            try wrapper.write(to: exportFile, originalContentsURL: nil)

            return exportDirectory
        } catch {
            FileLog.shared.addMessage("[Export] Prepare failed with error: \(error)")
            return nil
        }
    }
}
