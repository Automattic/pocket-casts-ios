import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class DatabaseExport {
    private let fileManager = FileManager.default
    private var loadingAlert: ShiftyLoadingAlert?
    
    /// The resulting file name of the zip file
    private let exportName = "Pocket Casts Export"

    /// ZIPs the users SQLite database and shows a share dialog for them to share it with us
    func exportDatabase(from controller: UIViewController, completion: @escaping () -> Void) {
        loadingAlert = ShiftyLoadingAlert(title: L10n.exporting)
        loadingAlert?.showAlert(controller, hasProgress: false, completion: { [weak self] in
            self?.export { url in
                self?.share(url: url, from: controller, completion: completion)
            }
        })
    }

    /// Open the resulting zip file in the share sheet, or show an error
    private func share(url: URL?, from controller: UIViewController, completion: @escaping () -> Void) {
        loadingAlert?.hideAlert(false)
        loadingAlert = nil

        guard let url else {
            SJUIUtils.showAlert(title: L10n.settingsExportError, message: nil, from: controller)
            return
        }
        
        // Share the file
        let shareSheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareSheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
            // Attempt to cleanup the temporary file
            self?.cleanup(url: url)

            completion()
        }

        controller.present(shareSheet, animated: true, completion: nil)
    }

    /// Attempt to remove the temporary export directory and files
    private func cleanup(url: URL) {
        do {
            try fileManager.removeItem(at: url.deletingLastPathComponent())
        } catch {
            FileLog.shared.addMessage("[Export] Could not cleanup file: \(error)")
        }
    }

    /// Create a zip of the database and prefrences
    private func export(_ handler: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let exportFolder = self.prepareFiles() else {
                handler(nil)
                return
            }

            let coordinator = NSFileCoordinator()

            // The file coordinate will zip the export folder for us
            coordinator.coordinate(readingItemAt: exportFolder, options: .forUploading, error: nil) { zipURL in
                do {
                    // The generated zip file is only available until this block exits
                    // so we need to move it to a more permanent location
                    let tempURL = exportFolder.appendingPathComponent("\(self.exportName).zip")
                    try self.fileManager.moveItem(at: zipURL, to: tempURL)

                    DispatchQueue.main.async {
                        handler(tempURL)
                    }
                } catch {
                    FileLog.shared.addMessage("[Export] Could not generate zip file: \(error)")
                    handler(nil)
                }
            }
        }
    }

    /// Copies the database and preferences to a temporary directory
    private func prepareFiles() -> URL? {
        do {
            let databaseURL = URL(fileURLWithPath: DataManager.pathToDb())

            // Create a temporary directory to store the files in
            let temporaryDirectory = try fileManager.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: databaseURL,
                                                         create: true)

            let exportDirectory = temporaryDirectory.appendingPathComponent(exportName, isDirectory: true)

            try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

            // Write the preferences to the export folder
            let preferencesFile = exportDirectory.appendingPathComponent("preferences.plist", isDirectory: false)
            try writePreferences(to: preferencesFile)

            // Copy the database file into the export folder
            let databaseFile = exportDirectory.appendingPathComponent("database.sqlite", isDirectory: false)
            try fileManager.copyItem(at: databaseURL, to: databaseFile)

            return exportDirectory
        } catch {
            FileLog.shared.addMessage("[Export] Prepare failed with error: \(error)")
            return nil
        }
    }

    /// Save the preferences to the url
    private func writePreferences(to url: URL) throws {
        guard
            let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first,
            let bundle = Bundle.main.bundleIdentifier
        else {
            return
        }

        let preferencesFile = library.appendingPathComponent("Preferences/\(bundle).plist")
        try fileManager.copyItem(at: preferencesFile, to: url)
    }
}
