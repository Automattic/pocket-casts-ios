import Foundation

@MainActor
class EpisodeChatViewModel: ObservableObject {
    let episodeTitle: String
    let podcastName: String

    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var inputText = ""
    @Published var isPlaying = true
    @Published private var followUpPrompts: [String] = []

    // MARK: - Feedback State

    @Published private(set) var feedbackDismissed = false
    private(set) var feedbackResult: ChatFeedbackResult?

    var shouldShowFeedbackToast: Bool {
        !feedbackDismissed && messages.filter({ $0.role == .assistant }).count >= 3
    }

    private var initialPrompts: [String] {
        [
            L10n.chatSuggestedSummary,
            L10n.chatSuggestedTakeaways,
            L10n.chatSuggestedTopics
        ]
    }

    var currentPrompts: [String] {
        messages.isEmpty ? initialPrompts : followUpPrompts
    }

    var showChips: Bool {
        !isTyping && !currentPrompts.isEmpty
    }

    init(episodeTitle: String, podcastName: String) {
        self.episodeTitle = episodeTitle
        self.podcastName = podcastName
        self.isPlaying = PlaybackManager.shared.playing()
    }

    func togglePlayback() {
        PlaybackManager.shared.playPause()
        isPlaying = PlaybackManager.shared.playing()
    }

    func send(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""

        isTyping = true

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            let response = mockResponse(for: text)
            messages.append(response)
            followUpPrompts = generateFollowUps(for: text)
            isTyping = false
        }
    }

    // MARK: - Feedback Actions

    func submitFeedback(_ result: ChatFeedbackResult) {
        feedbackResult = result
    }

    func dismissFeedback() {
        feedbackDismissed = true
    }

    // MARK: - Follow-Up Suggestions

    private func generateFollowUps(for lastInput: String) -> [String] {
        let lowered = lastInput.lowercased()

        if lowered.contains("summar") {
            return [L10n.chatSuggestedTakeaways, L10n.chatSuggestedTopics]
        }

        if lowered.contains("takeaway") || lowered.contains("key") {
            return [L10n.chatSuggestedSummary, L10n.chatSuggestedTopics]
        }

        if lowered.contains("topic") || lowered.contains("discuss") {
            return [L10n.chatSuggestedSummary, L10n.chatSuggestedTakeaways]
        }

        return [L10n.chatSuggestedSummary, L10n.chatSuggestedTakeaways]
    }

    // MARK: - Mock Responses

    private func mockResponse(for input: String) -> ChatMessage {
        let lowered = input.lowercased()

        if lowered.contains("summar") {
            return ChatMessage(
                role: .assistant,
                content: "This episode of \(podcastName) explores several fascinating topics. The host discusses the evolving landscape of technology and its impact on daily life, featuring interviews with industry experts who share their unique perspectives. Key themes include innovation, human connection, and the balance between progress and mindfulness."
            )
        }

        if lowered.contains("takeaway") || lowered.contains("key") {
            return ChatMessage(
                role: .assistant,
                content: "Here are the key takeaways from \"\(episodeTitle)\":\n\n1. Technology should enhance human connection, not replace it\n2. Small, consistent habits lead to the biggest changes over time\n3. The most successful innovators prioritize empathy in their design process\n4. Mindfulness practices can significantly improve creative output"
            )
        }

        if lowered.contains("topic") || lowered.contains("discuss") {
            return ChatMessage(
                role: .assistant,
                content: "The main topics discussed in this episode include:\n\n\u{2022} The future of AI and its ethical implications\n\u{2022} Personal productivity frameworks\n\u{2022} The science of habit formation\n\u{2022} Interviews with leading researchers in cognitive science\n\u{2022} Practical tips for maintaining work-life balance"
            )
        }

        if lowered.contains("similar") || lowered.contains("related") || lowered.contains("find") || lowered.contains("recommend") {
            return ChatMessage(
                role: .assistant,
                content: "Based on the themes in this episode, here are some episodes you might enjoy:",
                relatedEpisodes: [
                    RelatedEpisode(
                        title: "The Science of Productivity",
                        podcastName: "Hidden Brain",
                        subtitle: "Explores the psychology behind getting things done"
                    ),
                    RelatedEpisode(
                        title: "How to Build Better Habits",
                        podcastName: "The Tim Ferriss Show",
                        subtitle: "Practical frameworks for lasting change"
                    ),
                    RelatedEpisode(
                        title: "The Ethics of Innovation",
                        podcastName: "Pivot",
                        subtitle: "A deep dive into tech responsibility"
                    )
                ]
            )
        }

        return ChatMessage(
            role: .assistant,
            content: "That's a great question about \"\(episodeTitle).\" Based on the episode content, the host covers this topic around the 15-minute mark, discussing how these ideas connect to broader themes of personal growth and technology's role in society. Would you like me to go deeper on any specific aspect?"
        )
    }
}
