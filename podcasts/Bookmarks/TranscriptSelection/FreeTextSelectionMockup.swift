import SwiftUI

// MARK: - Mockup: Free Text Selection Design
// This is a static mockup to visualize the free text selection approach.
// Instead of per-cue toggle rows, the full transcript is shown as continuous
// text with a highlighted selection that the user can adjust with drag handles.

private let sampleTranscript = """
And I think that's something that a lot of people don't realize about the admissions process. \
that's the thing about selective admissions — the difference between the kid who gets in and \
the kid who doesn't is often basically noise. \
Right, and that's why some researchers have floated the lottery idea. You set a bar for who's \
qualified, and past that, you just draw names. \
It sounds radical, but it's arguably more honest than pretending there's a meaningful distinction \
between applicant 1,800 and applicant 2,100. \
And meanwhile the debt side of this is its own crisis. Families are taking on six figures for a \
credential that for most of the last century, was basically a guaranteed ticket to the middle \
class. And that promise is getting shakier. \
The return on investment question is real. You look at certain degree programs and the math just \
doesn't work out for most graduates. \
But then you have people saying, well, college isn't just about ROI. It's about civic engagement, \
critical thinking, exposure to new ideas. And that's true, but it's a hard sell when you're \
staring at a hundred thousand dollars in loans.
"""

// The "selected" portion — what would be auto-highlighted around the bookmark timestamp
private let selectedStart = 93  // "that's the thing about selective admissions..."
private let selectedEnd = 456   // "...applicant 2,100."

struct FreeTextSelectionMockup: View {
    @State private var titleText = "Selective Admissions Debate"

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Highlight a passage for this bookmark")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.subheadline)
                    .padding(.top, 4)

                // The key change: one continuous text view with highlight
                transcriptTextView
                    .frame(maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Selection info
                HStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("364 characters selected")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                    Text("\u{00b7}")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                    Text("01:23 – 02:47")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                }

                // Title field (same as current design)
                VStack(alignment: .leading, spacing: 6) {
                    Text("TITLE")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                        .fontWeight(.semibold)

                    TextField("Bookmark", text: $titleText)
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .bold))
                        .textFieldStyle(.plain)
                        .tint(Color(red: 0.9, green: 0.3, blue: 0.3))
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Color.white.opacity(0.2).frame(height: 1)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.12, green: 0.1, blue: 0.1))
            .navigationTitle("Edit transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color(red: 0.9, green: 0.3, blue: 0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    /// Continuous text with highlighted selection — simulates what a UITextView
    /// with native selection handles would look like
    private var transcriptTextView: some View {
        ScrollView {
            highlightedTranscript
                .padding(16)
        }
        .padding(.vertical, 8)
    }

    /// Builds an AttributedString with the selected portion highlighted
    private var highlightedTranscript: some View {
        let fullText = sampleTranscript
        let startIdx = fullText.index(fullText.startIndex, offsetBy: min(selectedStart, fullText.count))
        let endIdx = fullText.index(fullText.startIndex, offsetBy: min(selectedEnd, fullText.count))

        let before = String(fullText[fullText.startIndex..<startIdx])
        let selected = String(fullText[startIdx..<endIdx])
        let after = String(fullText[endIdx..<fullText.endIndex])

        return VStack(alignment: .leading, spacing: 0) {
            // Render as a single flowing text block with inline highlighting
            (
                Text(before)
                    .foregroundColor(.white.opacity(0.35))
                +
                Text(selected)
                    .foregroundColor(.white)
                    .underline(color: Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.0))
                    .background(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.25))
                +
                Text(after)
                    .foregroundColor(.white.opacity(0.35))
            )
            .font(.system(.body, design: .serif))
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Simulated selection handles (visual indicator only)
            // In the real implementation, UITextView provides these natively
        }
    }
}

#Preview("Free Text Selection — Dark") {
    FreeTextSelectionMockup()
        .preferredColorScheme(.dark)
}

#Preview("Comparison: Current Cue-Based") {
    CueBasedMockup()
        .preferredColorScheme(.dark)
}

// MARK: - Comparison: Current cue-based design for side-by-side

private struct CueBasedMockup: View {
    @State private var titleText = "Selective Admissions Debate"
    private let cues = [
        (text: "And I think that's something that a lot of people don't realize about the admissions process.", selected: false),
        (text: "that's the thing about selective admissions — the difference between the kid who gets in and the kid who doesn't is often basically noise.", selected: true),
        (text: "Right, and that's why some researchers have floated the lottery idea. You set a bar for who's qualified, and past that, you just draw names.", selected: true),
        (text: "It sounds radical, but it's arguably more honest than pretending there's a meaningful distinction between applicant 1,800 and applicant 2,100.", selected: true),
        (text: "And meanwhile the debt side of this is its own crisis. Families are taking on six figures for a credential that for most of the last century, was basically a guaranteed ticket to the middle class. And that promise is getting shakier.", selected: false),
        (text: "The return on investment question is real. You look at certain degree programs and the math just doesn't work out for most graduates.", selected: false),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Select a transcript passage for this bookmark")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.subheadline)
                    .padding(.top, 4)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(cues.enumerated()), id: \.offset) { _, cue in
                            Text(cue.text)
                                .font(.system(.body, design: .serif))
                                .lineSpacing(3)
                                .foregroundStyle(cue.selected ? .white : .white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(cue.selected ? Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.25) : Color.clear)
                                )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 8)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 6) {
                    Text("3 lines")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                    Text("\u{00b7}")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                    Text("01:23 – 02:47")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("TITLE")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.caption)
                        .fontWeight(.semibold)

                    TextField("Bookmark", text: $titleText)
                        .foregroundStyle(.white)
                        .font(.system(size: 22, weight: .bold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Color.white.opacity(0.2).frame(height: 1)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.12, green: 0.1, blue: 0.1))
            .navigationTitle("Edit transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {} label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {} label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color(red: 0.9, green: 0.3, blue: 0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
