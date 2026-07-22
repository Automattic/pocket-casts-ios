import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ShowHTMLView: View {
    let title: String
    let urlString: String

    @State private var htmlContent: NSAttributedString?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
        .padding([.horizontal, .top], 80)
        .frame(width: 1200, height: 920, alignment: .topLeading)
        .task {
            await loadHTML()
        }
        .remotePlayPause()
    }

    @ViewBuilder
    private var content: some View {
        if let htmlContent {
            // Scrolling UITextView has no intrinsic height; it fills the space the
            // header leaves inside the modal's fixed frame.
            ScrollableTextView(attributedText: htmlContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 16) {
                ProgressView()
                Text(L10n.loading)
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loadHTML() async {
        let html: String
        do {
            html = try await fetchHTML(from: urlString)
        } catch {
            html = L10n.tvDiscoverRowFailedToLoadTitle
        }
        htmlContent = HTMLToAttributedStringConverter.attributedString(from: html)
    }

    func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard (200...299).contains(response.extractStatusCode()) else {
            throw URLError(.badServerResponse)
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        return html
    }
}
