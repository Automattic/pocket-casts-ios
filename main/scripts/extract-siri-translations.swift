#!/usr/bin/env swift
import Foundation

let siriShortcutKeyPrefix = "siri_intent_definition_key_"
let fileManager = FileManager.default
let projectRoot: URL = {
    /// Crawl our way up the project tree until we find the root
    var candidate = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    while !fileManager.fileExists(atPath: candidate.appendingPathComponent(".git").path), candidate.path != "/" {
        candidate.deleteLastPathComponent()
    }

    return candidate
}()

let projectDir = projectRoot.appendingPathComponent("podcasts")

guard fileManager.fileExists(atPath: projectDir.path) else {
    print("Must run script from project root folder")
    exit(1)
}

var projectLanguages: [String] = {
    (try? fileManager.contentsOfDirectory(atPath: projectDir.path)
        .filter { $0.hasSuffix(".lproj") }
        .map { $0.replacingOccurrences(of: ".lproj", with: "") }
        .filter { $0 != "Base" }
    ) ?? []
}()

func readStrings(path: String) -> [String: String] {
    do {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: path))
        let source = try PropertyListSerialization.propertyList(from: sourceData, options: [], format: nil) as! [String: String]
        return source
    }
    catch {
        print("Error reading \(path): \(error)")
        return [:]
    }
}

var sourceStrings: [String: String] {
    let sourcePath = projectDir.path.appending("/en.lproj/Localizable.strings")
    return readStrings(path: sourcePath).filter {
        $0.key.hasPrefix(siriShortcutKeyPrefix)
    }
}

func readProjectTranslations(for language: String) -> [String: String] {
    let path = projectDir.appendingPathComponent("\(language).lproj/Localizable.strings").path
    return readStrings(path: path).filter {
        $0.key.hasPrefix(siriShortcutKeyPrefix)
    }
}

func writeTranslations(_ translations: String, language: String) {
    let languageDir = projectDir.path.appending("/\(language).lproj")
    let stringsPath = languageDir.appending("/Intents.strings")
    let encoding = String.Encoding.utf16

    do {
        try translations.write(toFile: stringsPath, atomically: true, encoding: encoding)
    }
    catch {
        print("Error writing translation to \(stringsPath): \(error)")
    }
}

for language in projectLanguages {
    let projectTranslations = readProjectTranslations(for: language)
    var translations = [String]()

    for (key, value) in sourceStrings {
        let translation = projectTranslations[key] ?? value
        let adjustedKey = key.replacingOccurrences(of: siriShortcutKeyPrefix, with: "")
        
        translations.append("\"\(adjustedKey)\" = \"\(translation)\";\n")
    }

    guard !translations.isEmpty else {
        continue
    }

    let output = translations.sorted().joined(separator: "\n")

    writeTranslations(output, language: language)
}

print("Siri Shortcut translations applied.")
