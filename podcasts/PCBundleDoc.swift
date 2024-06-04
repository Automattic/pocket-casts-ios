import PocketCastsDataModel
import SwiftUI

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

    static func `import`(from wrapper: FileWrapper) {
        print(wrapper)

        // Import database
        let databaseDestination = FileManager.databaseURL
        if let database = wrapper.fileWrappers?.first(where: { $0.key == Constants.databaseFilename }) {
            try! database.value.write(to: databaseDestination, originalContentsURL: nil)
        }

        // Import Preferences
        if let preferences = wrapper.fileWrappers?.first(where: { $0.key == Constants.preferencesFilename }) {
            let plistToCopy = FileManager.default.temporaryDirectory.appendingPathComponent("PocketCastsImportedPreferences", conformingTo: .propertyList)
            try! preferences.value.write(to: plistToCopy, originalContentsURL: nil)

            if let myDict = NSDictionary(contentsOfFile: plistToCopy.path) {
                myDict.forEach {
                    UserDefaults.standard.setValue($0.value, forKey: $0.key as! String)
                }
            }
        }

        exit(0)
    }

    init(configuration: ReadConfiguration) throws {
        PCBundleDoc.`import`(from: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let databaseFileWrapper = try FileWrapper(url: FileManager.databaseURL)
        databaseFileWrapper.preferredFilename = Constants.databaseFilename

        let preferencesFileWrapper = try FileWrapper(url: FileManager.preferencesURL!)
        preferencesFileWrapper.preferredFilename = Constants.preferencesFilename

        let wrapper = FileWrapper(directoryWithFileWrappers: [
            Constants.databaseFilename: databaseFileWrapper,
            Constants.preferencesFilename: preferencesFileWrapper
        ])
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
            return nil
        }

        return library.appendingPathComponent("Preferences/\(bundle).plist")
    }

    fileprivate static var databaseURL: URL {
        URL(fileURLWithPath: DataManager.pathToDb())
    }
}
