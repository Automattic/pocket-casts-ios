import PocketCastsDataModel
import SwiftUI

extension UTType {
    static var pcasts = UTType(filenameExtension: "pcasts", conformingTo: .package)!
}

struct PCBundleDoc: FileDocument {
    static var readableContentTypes = [UTType.pcasts]

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
        if let database = wrapper.fileWrappers?.first(where: { $0.0.hasSuffix("sqlite3") }) {
            try! database.value.write(to: databaseDestination, originalContentsURL: nil)
        }

        // Import Preferences
        if let preferences = wrapper.fileWrappers?.first(where: { $0.0.hasSuffix("plist") }) {
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
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "database.sqlite": try FileWrapper(url: FileManager.databaseURL),
            "preferences.plist": try FileWrapper(url: FileManager.preferencesURL!)
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

