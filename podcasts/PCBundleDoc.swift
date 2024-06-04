import PocketCastsDataModel
import SwiftUI
import PocketCastsUtils

extension UTType {
    static var pcasts = UTType(filenameExtension: "pcasts", conformingTo: .package)!
}

struct PCBundleDoc: FileDocument {
    static var readableContentTypes = [UTType.pcasts]

    enum Constants {
        static let databaseFilename = "database.sqlite"
        static let preferencesFilename = "preferences.plist"
    }

    init() {}

    static func delete() {
        try! FileManager.default.removeItem(at: FileManager.databaseURL)
        try! FileManager.default.removeItem(at: FileManager.preferencesURL!)

        UserDefaults.resetStandardUserDefaults()
        exit(0)
    }

    static func performImport(from wrapper: FileWrapper) throws {
        // Import database
        let databaseDestination = FileManager.databaseURL
        if let database = wrapper.fileWrappers?.first(where: { $0.key == Constants.databaseFilename }) {
            try database.value.write(to: databaseDestination, originalContentsURL: nil)
        }

        // Import Preferences
        if let preferences = wrapper.fileWrappers?.first(where: { $0.key == Constants.preferencesFilename }) {
            let plistToCopy = FileManager.default.temporaryDirectory.appendingPathComponent("PocketCastsImportedPreferences", conformingTo: .propertyList)
            try preferences.value.write(to: plistToCopy, originalContentsURL: nil)

            if let myDict = NSDictionary(contentsOfFile: plistToCopy.path) {
                myDict.forEach {
                    UserDefaults.standard.setValue($0.value, forKey: $0.key as! String)
                }
            }
        }

        exit(0)
    }

    init(configuration: ReadConfiguration) throws {
        try PCBundleDoc.performImport(from: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {

        let wrapper = FileWrapper(directoryWithFileWrappers: [:])

        let databaseFileWrapper = try FileWrapper(url: FileManager.databaseURL)
        databaseFileWrapper.preferredFilename = Constants.databaseFilename
        wrapper.addFileWrapper(databaseFileWrapper)

        if let prefURL = FileManager.preferencesURL {
            let preferencesFileWrapper = try FileWrapper(url: prefURL)
            preferencesFileWrapper.preferredFilename = Constants.preferencesFilename
            wrapper.addFileWrapper(preferencesFileWrapper)
        }

        wrapper.preferredFilename = Date().formatted(.iso8601)
        return wrapper
    }
}

extension FileManager {
    fileprivate static var preferencesURL: URL? {
        guard
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first,
            let bundle = Bundle.main.bundleIdentifier
        else {
            FileLog.shared.addMessage("Failed to find library directory or bundle identifier")
            return nil
        }

        return library.appendingPathComponent("Preferences/\(bundle).plist")
    }

    fileprivate static var databaseURL: URL {
        URL(fileURLWithPath: DataManager.pathToDb())
    }
}
