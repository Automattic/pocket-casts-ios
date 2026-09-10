import Foundation

/// A poll a reader answers without leaving a What's New message.
///
/// TODO: server parsing — the published contract only sketches a poll. The implementation plan's
/// example carries a single `question` and its `options` on the block itself and says the rest of
/// the fields "will be defined when the poll use case is implemented", so this decodes that shape
/// and a `questions` array for a poll that asks more than one thing. Revisit once the contract
/// lands, including whether a question can be optional, free-text, or scored.
public struct WhatsNewPoll: Decodable, Hashable {
    /// The identifier a response is recorded against, stable across the message's localized variants.
    public let pollId: String

    /// The questions the poll asks, in the order they were published.
    public let questions: [Question]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pollId = try container.decode(String.self, forKey: .pollId)

        // A poll that asks one thing puts it on the block itself rather than in a `questions` array,
        // so the block's own decoder is what that question is read from.
        let published = try container.decode(LossyDecodedArray<Question>.self, forKey: .questions).wrappedValue
        questions = published.isEmpty ? [try Question(from: decoder)] : published
    }

    private enum CodingKeys: String, CodingKey {
        case pollId
        case questions
    }

    /// One question of a poll and the options it's answered with.
    public struct Question: Decodable, Hashable, Identifiable {
        /// The identifier an answer is recorded against.
        public let id: String

        /// What the question asks.
        public let text: String

        /// Whether more than one option can be chosen.
        public let allowsMultipleAnswers: Bool

        /// The options to choose between, in the order they were published.
        public let options: [Option]

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // The single-question shape names the question `question` and gives it no ID of its own,
            // leaving the poll's ID as the only thing to record its answer against.
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? container.decode(String.self, forKey: .pollId)
            text = try container.decodeIfPresent(String.self, forKey: .text) ?? container.decode(String.self, forKey: .question)
            allowsMultipleAnswers = try container.decodeIfPresent(Bool.self, forKey: .allowsMultipleAnswers) ?? false
            options = try container.decode(LossyDecodedArray<Option>.self, forKey: .options).wrappedValue

            guard !options.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .options, in: container, debugDescription: "A question with nothing to choose between")
            }
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case pollId
            case text
            case question
            case allowsMultipleAnswers
            case options
        }
    }

    /// One of the answers a question can be given.
    public struct Option: Decodable, Hashable, Identifiable {
        /// The identifier the answer is recorded as.
        public let id: String

        /// What the option reads as.
        public let label: String
    }
}
