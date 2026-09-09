import Foundation

public extension WhatsNewCatalog {
    /// A catalog shaped like the published contract, for previews and manual testing.
    ///
    /// The messages are published relative to now rather than on fixed dates, so the feed keeps
    /// rendering the same spread of relative dates however long after this was written it's read.
    static let mock = mock(publishedDaysAgo: [0, 8, 27, 36, 62, 90, 118])

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
    /// Between them they cover every message type and every block the app renders. The user research
    /// message carries a `poll` block the app doesn't model, so anything rendering the mock exercises
    /// a page that drops a block and still has something left to show. The release notes message is
    /// taller than any screen, so a page that has to scroll is covered too.
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
        """,
        """
        {
          "id": "01K2Y4H2P6R8T0VXZB1DFG3JKM",
          "type": "known_issue",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "summary": { "title": "Downloads stalling on cellular", "label": "Known Issue" },
          "content": {
            "title": "Downloads stalling on cellular",
            "pages": [
              {
                "blocks": [
                  {
                    "type": "video",
                    "sources": [
                      { "url": "https://static.pocketcasts.com/whats-new/media/retry-download.mp4", "mimeType": "video/mp4" }
                    ],
                    "posterUrl": "https://static.pocketcasts.com/whats-new/media/retry-download-poster.webp",
                    "captionsUrl": "https://static.pocketcasts.com/whats-new/media/retry-download.vtt",
                    "alt": "Swiping an episode to start its download again"
                  },
                  { "type": "heading", "level": 2, "text": "We're on it" },
                  { "type": "paragraph", "content": "Some downloads stop short on a cellular connection. Swipe the episode and download it again while we work on a fix." }
                ]
              }
            ]
          }
        }
        """,
        """
        {
          "id": "01K2Y5R3TZ9B4D6MHXKQ0PWNC7",
          "type": "announcement",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "summary": { "title": "Everything new this month", "label": "Announcement" },
          "content": {
            "title": "Everything new this month",
            "pages": [
              {
                "blocks": [
                  { "type": "heading", "level": 2, "text": "Playback" },
                  { "type": "paragraph", "content": "Playback speed is now per podcast as well as per episode, so a show you always listen to at 1.5x stays there without you setting it again each time." },
                  { "type": "paragraph", "content": "Skipping forward and back keeps its place when you change episodes mid-chapter, and the sleep timer can now be extended from the lock screen." },
                  { "type": "heading", "level": 2, "text": "Downloads" },
                  { "type": "paragraph", "content": "Automatic downloads start as soon as an episode is released rather than waiting for the next refresh, and a download that fails is retried once on its own before it asks you to try again." },
                  {
                    "type": "image",
                    "url": "https://static.pocketcasts.com/whats-new/media/downloads-detail.webp",
                    "width": 1200,
                    "height": 750,
                    "alt": "The downloads screen with an episode part way through"
                  },
                  { "type": "heading", "level": 2, "text": "Sync" },
                  { "type": "paragraph", "content": "Up Next syncs faster between devices, and a queue you reorder offline no longer loses that order when you come back online." },
                  { "type": "paragraph", "content": "Folders sync on their own schedule instead of waiting for a full refresh, so a folder you make on the web shows up on your phone within a minute or so." },
                  { "type": "heading", "level": 2, "text": "Fixes" },
                  { "type": "paragraph", "content": "We fixed the artwork that stayed blank after a podcast changed its feed, the filter that counted archived episodes, and a crash when a chapter had no title." },
                  { "type": "paragraph", "content": "Thanks to everyone who wrote in about these — most of them were reported by people using the app every day." },
                  { "type": "action", "label": "Read the full release notes", "url": "https://blog.pocketcasts.com", "style": "primary" }
                ]
              }
            ]
          }
        }
        """
    ]
}
