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
    /// Between them they cover every message type, a single page and a pager, a page whose text is
    /// longer than the screen, a page whose action names an event no client implements, and the
    /// poll a research message is built around.
    ///
    /// The images point at artwork that's actually there, so previews render something rather than
    /// a hole the size of the image.
    private static let mockMessages = [
        """
        {
          "id": "01K2Y3BQ7C4M8XR5NHVD2WTGJ9",
          "type": "tip",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "title": "Sort your Up Next",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/82e37e80-755d-0138-eddc-0acc26574db2.jpg",
                "width": 420,
                "height": 420,
                "alt": "The sort menu open in Up Next"
              },
              "heading": "Put the queue in the order you want",
              "description": "Drag an episode by its handle to move it, or sort the whole queue by release date, duration, or the order you added them.",
              "action": { "event": "open_up_next", "label": "Open Up Next" }
            }
          ]
        }
        """,
        """
        {
          "id": "01K2Y3D5J1H7QZP0B6RXKA4N3T",
          "type": "new_feature",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "plus", "patron"], "minimumAppVersion": null },
          "title": "Introducing Playlists",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/3782b780-0bc5-012e-fb02-00163e1b201c.jpg",
                "width": 420,
                "height": 420,
                "alt": "A playlist of episodes"
              },
              "heading": "Filters are now Playlists",
              "description": "Build a playlist by hand, or let a smart playlist keep itself up to date from the rules you set."
            },
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg",
                "width": 420,
                "height": 420,
                "alt": "The rules that keep a smart playlist up to date"
              },
              "heading": "Start with the one you have",
              "description": "Every filter you made is already a playlist, with the same rules and the same episodes in it.",
              "action": { "event": "open_playlists", "label": "Try Playlists" }
            }
          ]
        }
        """,
        """
        {
          "id": "01K2Y2CFD0VAWA4N74D3N6JTVK",
          "type": "research",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "future_audience"] },
          "title": "Help shape the player",
          "description": "Which improvement would make the biggest difference to your listening? It takes one tap.",
          "poll": {
            "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
            "pollKey": "player_improvements_2026",
            "question": "What should we improve next?",
            "options": [
              { "id": "01K2Y2S65F3RWQK5X2A0C7VN8P", "pollOptionKey": "up_next_controls", "label": "Up Next controls" },
              { "id": "01K2Y2S65F6M1TDYB9E4HJQZR2", "pollOptionKey": "podcast_discovery", "label": "Podcast discovery" },
              { "id": "01K2Y2S65F8KPX3VNG7WD5ST6A", "pollOptionKey": "transcript_tools", "label": "Transcript tools" },
              { "id": "01K2Y2S65FB0ZCM6QH2YE9XF4D", "pollOptionKey": "sleep_timer", "label": "The sleep timer" }
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
          "title": "Ads to support Pocket Casts",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/3782b780-0bc5-012e-fb02-00163e1b201c.jpg",
                "width": 420,
                "height": 420,
                "alt": "An ad between two episodes in the list"
              },
              "heading": "A small number of ads, from today",
              "description": "We're adding a small number of ads to the free app so we can keep building Pocket Casts for everyone. Plus and Patron stay ad free.",
              "action": { "event": "open_upsell", "label": "See what Plus includes" }
            }
          ]
        }
        """,
        """
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "new_feature",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": ["free", "plus", "patron"] },
          "title": "Introducing episode transcripts",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/82e37e80-755d-0138-eddc-0acc26574db2.jpg",
                "width": 420,
                "height": 420,
                "alt": "Episode transcript open beside the player"
              },
              "heading": "Read along while you listen",
              "description": "Search a transcript, jump to a spoken phrase, and follow the conversation without losing your place."
            },
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg",
                "width": 420,
                "height": 420,
                "alt": "The transcript button on an episode"
              },
              "heading": "Try it in any supported episode",
              "description": "Open an episode with a transcript and choose the transcript view to get started.",
              "action": { "event": "open_podcasts", "label": "Try transcripts" }
            }
          ]
        }
        """,
        """
        {
          "id": "01K2Y4H2P6R8T0VXZB1DFG3JKM",
          "type": "known_issue",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "title": "Downloads stalling on cellular",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/9349e8d0-a87f-013a-d8af-0acc26574db2.jpg",
                "width": 420,
                "height": 420,
                "alt": "Swiping an episode to start its download again"
              },
              "heading": "We're on it",
              "description": "Some downloads stop short on a cellular connection. Swipe the episode and download it again while we work on a fix.",
              "action": { "event": "open_downloads_from_a_later_release", "label": "Open Downloads" }
            }
          ]
        }
        """,
        """
        {
          "id": "01K2Y5R3TZ9B4D6MHXKQ0PWNC7",
          "type": "announcement",
          "publishedAt": "$publishedAt",
          "targeting": { "audiences": [] },
          "title": "Everything new this month",
          "pages": [
            {
              "image": {
                "url": "https://static.pocketcasts.com/discover/images/420/3782b780-0bc5-012e-fb02-00163e1b201c.jpg",
                "width": 420,
                "height": 420,
                "alt": "The downloads screen with an episode part way through"
              },
              "heading": "Playback, downloads, sync, and a pile of fixes",
              "description": "Playback speed is now per podcast as well as per episode, so a show you always listen to at 1.5x stays there without you setting it again each time. Skipping forward and back keeps its place when you change episodes mid-chapter, and the sleep timer can now be extended from the lock screen.\\n\\nAutomatic downloads start as soon as an episode is released rather than waiting for the next refresh, and a download that fails is retried once on its own before it asks you to try again.\\n\\nUp Next syncs faster between devices, and a queue you reorder offline no longer loses that order when you come back online. Folders sync on their own schedule instead of waiting for a full refresh, so a folder you make on the web shows up on your phone within a minute or so.\\n\\nWe fixed the artwork that stayed blank after a podcast changed its feed, the filter that counted archived episodes, and a crash when a chapter had no title. Thanks to everyone who wrote in about these — most of them were reported by people using the app every day.",
              "action": { "event": "open_discover", "label": "Find something new" }
            }
          ]
        }
        """
    ]
}
