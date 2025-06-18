import Foundation
import Translation

struct AvailableLanguage: Identifiable, Hashable, Comparable {
    var id: Self { self }
    let locale: Locale.Language

    var shortName: String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }
    
    func localizedName() -> String {
        let locale = Locale.current

        guard let localizedName = locale.localizedString(forLanguageCode: shortName) else {
            return "Unknown language code"
        }
        return "\(localizedName) (\(shortName))"
    }

    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName() < rhs.localizedName()
    }
}

@available(iOS 18.0, *)
class TranslationsManager {
    private(set) var availableLanguages: [AvailableLanguage] = []
    private(set) var configuration: TranslationSession.Configuration?

    init() {
        prepareSupportedLanguages()
    }

    private func setupConfiguration(source: Locale.Language? = nil, target: Locale.Language? = nil) {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }
        configuration = .init(source: source, target: target)
    }
    
    func prepareSupportedLanguages() {
        Task { @MainActor in
            let supportedLanguages = await LanguageAvailability().supportedLanguages
            availableLanguages = supportedLanguages.map {
                AvailableLanguage(locale: $0)
            }
            .sorted()
        }
    }
    
    func translate(text: String, source: Locale.Language? = nil, target: Locale.Language? = nil) async throws -> String {
        setupConfiguration(source: source, target: target)
        guard let configuration else {
            throw NSError(domain: "Translation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing configuration"])
        }
        let session = try await TranslationSession.make(for: configuration)
        return try await translate(text: text, using: session)
    }
    
    func translate(text: String, using session: TranslationSession) async throws -> String {
        let response = try await session.translate(text)
        return response.targetText
    }
}
