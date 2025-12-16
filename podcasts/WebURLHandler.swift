import Foundation
import PocketCastsServer

struct WebURLHandler {
    private static let defaultVoice: TTSService.Voice = .male
    private static let defaultNfe: Int = 5

    static func handle(url: URL) async {
        do {
            // Call DiscoverServerHandler.search with the URL string
            guard let urlString = url.absoluteString.split(separator: "/import-file/").last,
                  let url = URL(string: String(urlString)) else {
                assertionFailure("Invalid URL \(url)")
                return
            }

            let feed = try await findFeed(for: url)

            if feed == nil {
            let (text, iconURL) = try await fetchTextFromDiffbot(for: url)
            print("Found Text: \(text?.prefix(500) ?? "None")")
            guard let text, !text.isEmpty else {
                print("No article text available for \(url)")
                return
            }

            do {
                try await synthesizeAndPlay(text: text, articleURL: url, iconURL: iconURL)
            } catch {
                print("Failed to generate or play TTS for \(url): \(error)")
            }
        } catch {
            // Silently fail if search or parsing fails
            print("WebURLHandler failed: \(error)")
            return
        }
    }

    static func findFeed(for url: URL) async throws -> URL? {
        let data = try await DiscoverServerHandler.shared.search(term: url.absoluteString)

        // Decode the search response
        let decoder = JSONDecoder()
        print("Output: \(data)")
        let response = try decoder.decode(PodcastSearchResponse.self, from: data)

        // Check if the response was successful
        guard response.success(),
              let result = response.result,
              let searchResults = result.searchResults,
              let firstResult = searchResults.first,
              let uuid = firstResult.uuid else {
            return nil
        }

        // Subscribe to the podcast using the UUID from the first result
//            ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true, completion: nil)
        print("Would subscribe to: \(firstResult.title)")

        return nil
    }

    /// Fetches readable text and icon for a URL using the Diffbot Article API.
    static func fetchTextFromDiffbot(for url: URL, token: String? = nil) async throws -> (text: String?, iconURL: String?) {
        let apiToken = token ?? Settings.diffbotApiKey
        guard !apiToken.isEmpty else {
            throw DiffbotError.missingApiToken
        }

        var components = URLComponents(string: "https://api.diffbot.com/v3/article")
        components?.queryItems = [
            URLQueryItem(name: "token", value: apiToken),
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "fields", value: "text,icon")
        ]

        guard let requestURL = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: requestURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let diffbotResponse = try JSONDecoder().decode(DiffbotArticleResponse.self, from: data)
        let article = diffbotResponse.objects?.first
        return (article?.text, article?.icon)
    }

    private static func synthesizeAndPlay(text: String, articleURL: URL, iconURL: String?) async throws {
        let service = try TTSService()
        _ = try await service.synthesizeStreaming(text: text, nfe: defaultNfe, voice: defaultVoice, title: ttsTitle(for: articleURL), url: articleURL.absoluteString, iconURL: iconURL)
    }

    private static func ttsTitle(for articleURL: URL) -> String {
        let hostComponent = articleURL.host?.replacingOccurrences(of: "www.", with: "") ?? ""
        let pathComponent = articleURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        if !pathComponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return pathComponent
        } else if !hostComponent.isEmpty {
            return hostComponent
        } else {
            return "Text to Speech"
        }
    }
}

private enum DiffbotError: Error {
    case missingApiToken
}

private struct DiffbotArticleResponse: Decodable {
    let objects: [DiffbotArticle]?
}

private struct DiffbotArticle: Decodable {
    let text: String?
    let icon: String?
}
