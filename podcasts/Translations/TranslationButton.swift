import SwiftUI
import Translation
import NaturalLanguage

@available(iOS 18.0, *)
struct TranslationButton: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var translationManager: TranslationsManager

    var body: some View {
        HStack {
            if translationManager.loadingState == .loading {
                LoadingView()
            } else {
                Button {
                    if let sourceText = translationManager.sourceText?(),
                       let detectedLang = NLLanguageRecognizer.dominantLanguage(for: sourceText) {
                        let localeLang = Locale.Language(identifier: detectedLang.rawValue)
                        translationManager.setupConfiguration(source: localeLang, target: translationManager.currentLanguage)
                    }
                } label: {
                    Image(systemName: "translate")
                        .renderingMode(.template)
                        .tint(theme.primaryIcon01)
                }
                .frame(width: 24.0, height: 24.0)
            }
        }
        .translationTask(translationManager.configuration) { session in
            do {
                if let sourceText = translationManager.sourceText?() {
                    try await session.prepareTranslation()

                    await MainActor.run {
                        translationManager.loadingState = .loading
                    }
                    let response = try await session.translate(sourceText)
                    await MainActor.run {
                        translationManager.loadingState = .idle
                        translationManager.translatedText?(response.targetText)
                    }
                }
            } catch {
                print("Error translations: \(error.localizedDescription)")
                await MainActor.run {
                    translationManager.loadingState = .idle
                }
            }
        }
        .task {
            await translationManager.prepareSupportedLanguages()
        }
        .padding(.horizontal, 5.0)
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        TranslationButton(
            translationManager: TranslationsManager(currentLanguage: Locale.current.language)
        )
        .previewWithAllThemes()
    } else {
        EmptyView()
    }
}
