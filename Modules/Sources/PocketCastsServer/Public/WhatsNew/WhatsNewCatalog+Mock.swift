import Foundation

public extension WhatsNewCatalog {
    /// A catalog shaped like the published contract, for previews and manual testing.
    ///
    /// The messages are published relative to now rather than on fixed dates, so the feed keeps
    /// rendering the same spread of relative dates however long after this was written it's read.
    static let mock = mock(publishedDaysAgo: [0, 8, 27, 36, 62])

    /// A catalog whose messages were published the given number of days ago, most recent first.
    ///
    /// Trimming or padding the list changes how many messages the catalog carries, so a preview can
    /// ask for a single message or a feed long enough to scroll.
    static func mock(publishedDaysAgo: [Int]) -> WhatsNewCatalog {
        let messages = zip(publishedDaysAgo, mockMessages).map { daysAgo, message in
            message.replacingOccurrences(of: "$publishedAt", with: iso8601(daysAgo: daysAgo))
        }
        let json = """
        {
          "schemaVersion": 1,
          "generatedAt": "\(iso8601(daysAgo: 0))",
          "platform": "ios",
          "locale": "en",
          "messages": [\(messages.joined(separator: ","))]
        }
        """

        do {
            return try decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))
        } catch {
            fatalError("The mock What's New catalog no longer matches the models: \(error)")
        }
    }

    private static func iso8601(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return ISO8601DateFormatter().string(from: date)
    }

    /// The messages the mock catalog is built from, each missing the `$publishedAt` the catalog fills in.
    ///
    /// The user research message carries a `poll` block the app doesn't model, so anything rendering
    /// the mock exercises a page that drops a block and still has something left to show.
    private static let mockMessages = [
        """
        {
          "id": "01K2Y3BQ7C4M8XR5NHVD2WTGJ9",
          "type": "tip",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "summary": { "title": "Sort your Up Next", "label": "Tips and Tricks" },
          "content": {
            "title": "Sort your Up Next",
            "pages": [
              {
                "blocks": [
                  { "type": "heading", "level": 2, "text": "Put the queue in the order you want" },
                  { "type": "paragraph", "content": "Drag an episode by its handle to move it, or sort the whole queue by release date, duration, or the order you added them." },
                  { "type": "action", "label": "Open Up Next", "url": "pocketcasts://upnext", "style": "primary" }
                ]
              }
            ]
          }
        }
        """,
        """
        {
          "id": "01K2Y3D5J1H7QZP0B6RXKA4N3T",
          "type": "new_feature",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "plus", "patron"] },
          "summary": { "title": "Introducing Playlists", "label": "New Feature" },
          "content": {
            "title": "Introducing Playlists",
            "pages": [
              {
                "blocks": [
                  { "type": "heading", "level": 2, "text": "Filters are now Playlists" },
                  { "type": "paragraph", "content": "Build a playlist by hand, or let a smart playlist keep itself up to date from the rules you set." }
                ]
              },
              {
                "blocks": [
                  { "type": "action", "label": "Try Playlists", "url": "pocketcasts://playlists", "style": "primary" }
                ]
              }
            ]
          }
        }
        """,
        """
        {
          "id": "01K2Y2CFD0VAWA4N74D3N6JTVK",
          "type": "research",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "future_audience"] },
          "summary": { "title": "Exploring social features", "label": "User Research" },
          "content": {
            "pages": [
              {
                "blocks": [
                  { "type": "paragraph", "content": "Which improvement would make the biggest difference?" },
                  { "type": "poll", "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT", "question": "What next?", "options": [] },
                  { "type": "paragraph", "content": "The survey takes about two minutes." }
                ]
              }
            ]
          }
        }
        """,
        """
        {
          "id": "01K2Y3F9V8N2C1LKS7DYE0RQMB",
          "type": "announcement",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free"] },
          "summary": { "title": "Ads to support Pocket Casts", "label": "Announcement" },
          "content": {
            "title": "Ads to support Pocket Casts",
            "pages": [
              {
                "blocks": [
                  { "type": "paragraph", "content": "We're adding a small number of ads to the free app so we can keep building Pocket Casts for everyone." },
                  { "type": "action", "label": "Read the announcement", "url": "https://blog.pocketcasts.com", "style": "secondary" }
                ]
              }
            ]
          }
        }
        """,
        """
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "new_feature",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "plus", "patron"], "minimumAppVersion": null },
          "summary": {
            "title": "Introducing episode transcripts",
            "label": "New Feature",
            "imageUrl": "https://static.pocketcasts.com/whats-new/media/transcripts-card.webp"
          },
          "content": {
            "title": "Introducing episode transcripts",
            "pages": [
              {
                "blocks": [
                  { "type": "heading", "level": 2, "text": "Read along while you listen" },
                  { "type": "paragraph", "content": "Search a transcript and follow the conversation." },
                  {
                    "type": "image",
                    "url": "https://static.pocketcasts.com/whats-new/media/transcripts-detail.webp",
                    "width": 1200,
                    "height": 750,
                    "alt": "Episode transcript open beside the player"
                  }
                ]
              },
              {
                "blocks": [
                  { "type": "action", "label": "Try transcripts", "url": "pocketcasts://podcasts", "style": "primary" }
                ]
              }
            ]
          }
        }
        """
    ]
}
