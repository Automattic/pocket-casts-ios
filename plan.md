# Chat with Episode — UI Exploration Plan

## Overview
Add a "Chat with Episode" feature to the player's overflow menu. Tapping it opens a full-screen chat sheet where users can ask questions about the episode. This iteration is **UI exploration only** — responses are mocked to explore the UX.

---

## 1. Add `chatWithEpisode` PlayerAction

**Files:**
- `Modules/Sources/PocketCastsDataModel/Public/Enums.swift` — add `case chatWithEpisode = "chat"` to `PlayerAction`
- `podcasts/Enumerations.swift` — add metadata:
  - `title()` → `L10n.chatWithEpisode` ("Chat with Episode")
  - `iconName()` → SF Symbol `"bubble.left.and.text.bubble.right"` (or custom asset)
  - `largeIconName()` → same or larger variant
  - `canBePerformedOn()` → only `Episode` (not `UserEpisode`)
  - `analyticsDescription` → `"chat_with_episode"`
- `podcasts/Enumerations.swift` — add to `defaultActions` array (at the end, so it lands in overflow by default)

## 2. Add Localized Strings

**File:** `podcasts/en.lproj/Localizable.strings`
- `"chat_with_episode"` = `"Chat with Episode"`
- `"chat_input_placeholder"` = `"Ask about this episode..."`
- `"chat_suggested_summary"` = `"Summarize this episode"`
- `"chat_suggested_takeaways"` = `"Key takeaways"`
- `"chat_suggested_topics"` = `"What topics are discussed?"`
- `"chat_suggested_related"` = `"Find similar episodes"`

## 3. Wire Up Shelf Action → Present Chat Sheet

**Files:**
- `podcasts/NowPlayingPlayerItemViewController+Shelf.swift` — add `case .chatWithEpisode` to `loadActionIntoShelf()` and add tap handler that presents the chat view
- `podcasts/ShelfActionsViewController+Table.swift` — add overflow menu tap handling for `.chatWithEpisode`
- `podcasts/NowPlayingActionsDelegate.swift` — add `func chatWithEpisodeTapped()` to protocol

**Presentation:** Full-screen sheet (`.large()` detent) wrapping the chat SwiftUI view in `ThemedHostingController`, following the pattern from `SharingModal` / `WhatsNewFullView`.

## 4. Create Chat UI (SwiftUI) — New Files

Directory: `podcasts/Chat/`

### 4a. `ChatMessage.swift` — Data Model
```
struct ChatMessage: Identifiable {
    let id: UUID
    let role: Role        // .user | .assistant
    let content: String
    let timestamp: Date
    let relatedEpisodes: [RelatedEpisode]?  // optional recommendations

    enum Role { case user, assistant }
}

struct RelatedEpisode: Identifiable {
    let id: UUID
    let title: String
    let podcastName: String
    let imageURL: URL?
}
```

### 4b. `ChatViewModel.swift` — ViewModel with Mock Responses
- Holds `@Published var messages: [ChatMessage]`
- Holds `@Published var isTyping: Bool`
- `suggestedPrompts: [String]` — shown when conversation is empty
- `func send(_ text: String)` — appends user message, simulates typing delay (~1.5s), appends mock assistant response
- Mock responses are context-aware based on keywords (summary, takeaways, topics, etc.)
- Receives episode metadata (title, podcast name) for personalized mock responses

### 4c. `EpisodeChatView.swift` — Main Chat View
Layout (top to bottom):
1. **Header bar** — Episode artwork (small), title, podcast name, dismiss button
2. **Message list** — `ScrollView` + `LazyVStack` of `ChatBubbleView` items, auto-scrolls to bottom
3. **Suggested prompts** — horizontal scroll of pill buttons (shown when no messages)
4. **Input bar** — `TextField` + send button, pinned to bottom with keyboard avoidance

### 4d. `ChatBubbleView.swift` — Individual Message Bubble
- User messages: right-aligned, tinted background
- Assistant messages: left-aligned, secondary background, with optional related episode cards
- Typing indicator (three animated dots) when `isTyping`

### 4e. `RelatedEpisodeCard.swift` — Episode Recommendation Card
- Small horizontal card with podcast artwork, episode title, podcast name
- Shown inline in assistant messages (like the Spotify screenshot)

### 4f. `SuggestedPromptPill.swift` — Tappable Prompt Chip
- Rounded pill with prompt text
- Tapping sends the prompt as a user message

## 5. Announcement Tooltip

**Approach:** Add an `AnnouncementFlow.chatWithEpisode` case and use the existing `WhatsNew` system to show a one-time tooltip. When the user opens the overflow menu for the first time after the feature ships, the chat action row gets highlighted (same pattern as bookmarks announcement using `actionsTable.selectRow()`).

**Files:**
- `podcasts/Whats New/Announcements.swift` — add `.chatWithEpisode` case to `AnnouncementFlow`
- `podcasts/ShelfActionsViewController.swift` — add `highlightChatIfNeeded()` in `viewDidAppear`, similar to `highlightAddBookmarksIfNeeded()`

## 6. File Summary

| New File | Purpose |
|----------|---------|
| `podcasts/Chat/ChatMessage.swift` | Message data model |
| `podcasts/Chat/ChatViewModel.swift` | ViewModel with mock AI responses |
| `podcasts/Chat/EpisodeChatView.swift` | Main chat screen |
| `podcasts/Chat/ChatBubbleView.swift` | Message bubble component |
| `podcasts/Chat/RelatedEpisodeCard.swift` | Episode recommendation card |
| `podcasts/Chat/SuggestedPromptPill.swift` | Tappable prompt chip |

| Modified File | Change |
|---------------|--------|
| `Enums.swift` | Add `.chatWithEpisode` case |
| `Enumerations.swift` | Add action metadata + default actions |
| `Localizable.strings` | Add chat strings |
| `NowPlayingPlayerItemViewController+Shelf.swift` | Wire shelf button + tap handler |
| `ShelfActionsViewController+Table.swift` | Wire overflow menu tap |
| `Announcements.swift` | Add announcement flow case |
| `ShelfActionsViewController.swift` | Add highlight logic |

---

## Out of Scope (Future)
- Real AI integration (FoundationModels / server LLM)
- Transcript context injection
- Conversation persistence
- Episode discovery/recommendations from real data
- Analytics events beyond shelf tap
