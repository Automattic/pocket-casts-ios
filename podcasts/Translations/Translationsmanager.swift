import Foundation
import Translation

struct AvailableLanguage: Identifiable, Hashable, Comparable {
    var id: Self { self }
    let locale: Locale.Language

    var shortName: String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }
    
    func localizedName() -> String {
        guard let localizedName = Locale.current.localizedString(forLanguageCode: shortName) else {
            return "Unknown language code"
        }
        return "\(localizedName) (\(shortName))"
    }

    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName() < rhs.localizedName()
    }
}

@available(iOS 18.0, *)
protocol TranslationsManaging {
    var availableLanguages: [AvailableLanguage] { get }
    var configuration: TranslationSession.Configuration? { get }
    var currentLanguage: Locale.Language { get }
    var sourceText: (() -> String?)? { get set }
    var translatedText: ((String?) -> Void)? { get set }

    init(currentLanguage: Locale.Language)

    func prepareSupportedLanguages() async
    func setupConfiguration(
        source: Locale.Language?,
        target: Locale.Language?
    )
    func translate(
        text: String,
        source: Locale.Language?,
        target: Locale.Language?,
        using session: TranslationSession
    ) async throws -> String
}

@available(iOS 18.0, *)
class TranslationsManager: ObservableObject, TranslationsManaging {
    enum LoadingState {
        case idle
        case loading
    }

    private(set) var availableLanguages: [AvailableLanguage] = []
    @Published private(set) var configuration: TranslationSession.Configuration?

    var sourceText: (() -> String?)? = nil
    var translatedText: ((String?) -> Void)? = nil

    let currentLanguage: Locale.Language

    @Published var loadingState: LoadingState = .idle

    required init(currentLanguage: Locale.Language) {
        self.currentLanguage = currentLanguage
        self.configuration = nil
    }

    func setupConfiguration(source: Locale.Language? = nil, target: Locale.Language? = nil) {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }
        configuration = .init(source: source, target: target)
    }

    func prepareSupportedLanguages() async {
        let supportedLanguages = await LanguageAvailability().supportedLanguages
        await MainActor.run {
            availableLanguages = supportedLanguages.map {
                AvailableLanguage(locale: $0)
            }
            .sorted()
        }
    }

    func translate(text: String, source: Locale.Language? = nil, target: Locale.Language? = nil, using session: TranslationSession) async throws -> String {
        let response = try await session.translate(text)
        return response.targetText
    }
}
