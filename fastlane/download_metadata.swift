#!/usr/bin/env swift

import Foundation

@discardableResult
func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    return output
}

let glotPressSubtitleKey = "app_store_subtitle"
let glotPressWhatsNewKey: String = {
    let versionNumber = shell("xcodebuild -project podcasts.xcodeproj -target podcasts -configuration Release -showBuildSettings | grep MARKETING_VERSION | tr -d 'MARKETING_VERSION ='").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return "v\(versionNumber)-whats-new"
}()

let glotPressDescriptionKey = "app_store_desc"
let glotPressKeywordsKey = "app_store_keywords"

struct Config {
    let baseFolder: String
    let baseURLString: String

    static let pocketCasts = Config(
        baseFolder: "./metadata",
        baseURLString: "https://translate.wordpress.com/projects/pocket-casts/ios/release-notes/"
    )
}

// iTunes Connect language code: GlotPress code
let languages = [
    "de-DE": "de",
    "es-ES": "es",
    "fr-FR": "fr",
    "it": "it",
    "ja": "ja",
    "nl-NL": "nl",
    "pt-BR": "pt-br",
    "ru": "ru",
    "sv": "sv",
    "zh-Hans": "zh-cn",
    "zh-Hant": "zh-tw"
]

func downloadTranslation(
    config: Config = .pocketCasts,
    languageCode: String,
    folderName: String
) {
    let glotPressURL = "\(config.baseURLString)\(languageCode)/default/export-translations?format=json"
    let requestURL = URL(string: glotPressURL)!
    let urlRequest = URLRequest(url: requestURL)
    let session = URLSession.shared

    let sema = DispatchSemaphore(value: 0)

    print("Downloading Language: \(languageCode)")

    let task = session.dataTask(with: urlRequest) {
        data, _, error in

        defer {
            sema.signal()
        }

        guard let data = data else {
            print("  Invalid data downloaded.")
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let jsonDict = json as? [String: Any]
        else {
            print("  JSON was not returned")
            return
        }

        var subtitle: String?
        var whatsNew: String?
        var keywords: String?
        var storeDescription: String?

        jsonDict.forEach { (key: String, value: Any) in

            guard let index = key.firstIndex(of: Character(UnicodeScalar(0004))) else {
                return
            }

            let keyFirstPart = String(key[..<index])

            guard let value = value as? [String],
                  let translation = value.first
            else {
                print("  No translation for \(keyFirstPart)")
                return
            }

            switch keyFirstPart {
            case glotPressSubtitleKey:
                subtitle = translation
            case glotPressKeywordsKey:
                keywords = translation
            case glotPressWhatsNewKey:
                whatsNew = translation
            case glotPressDescriptionKey:
                storeDescription = translation
            default:
                print("  Unknown key: \(keyFirstPart)")
            }
        }

        let languageFolder = "\(config.baseFolder)/\(folderName)"

        let fileManager = FileManager.default
        try? fileManager.createDirectory(atPath: languageFolder, withIntermediateDirectories: true, attributes: nil)

        do {
            let releaseNotesPath = "\(languageFolder)/release_notes.txt"

            /// Remove existing release notes in case they weren't translated for this release (that way `deliver` will fall back to the `default` locale)
            if FileManager.default.fileExists(atPath: releaseNotesPath) {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: releaseNotesPath))
            }

            try subtitle?.write(toFile: "\(languageFolder)/subtitle.txt", atomically: true, encoding: .utf8)
            try whatsNew?.write(toFile: "\(languageFolder)/release_notes.txt", atomically: true, encoding: .utf8)
            try keywords?.write(toFile: "\(languageFolder)/keywords.txt", atomically: true, encoding: .utf8)
            try storeDescription?.write(toFile: "\(languageFolder)/description.txt", atomically: true, encoding: .utf8)
        } catch {
            print("  Error writing: \(error)")
        }
    }

    task.resume()
    sema.wait()
}

languages.forEach { (key: String, value: String) in
    downloadTranslation(languageCode: value, folderName: key)
}

extension Array {
    var second: Element? { dropFirst().first }
}
