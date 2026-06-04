import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

protocol TranscriptSelectionRouter: AnyObject {
    func selectionSaved(title: String)
    func selectionDismissed()
}

class TranscriptSelectionViewModel: ObservableObject {
    weak var router: TranscriptSelectionRouter?

    let bookmark: Bookmark
    let cues: [TranscriptCue]
    let fullText: String
    let bookmarkCueIndex: Int

    @Published var startCueIndex: Int
    @Published var endCueIndex: Int
    @Published private(set) var selectedText: String = ""
    @Published var bookmarkTitle: String = ""
    @Published private(set) var isGeneratingTitle: Bool = false
    let isEditing: Bool

    private let bookmarkManager: BookmarkManager
    private let maxTitleLength = Constants.Values.bookmarkMaxTitleLength

    var selectedCueCount: Int { endCueIndex - startCueIndex + 1 }

    var selectionStartTime: TimeInterval {
        cues[startCueIndex].startTime
    }

    var selectionEndTime: TimeInterval {
        cues[endCueIndex].endTime
    }

    var formattedTimeRange: String {
        let start = TimeFormatter.shared.playTimeFormat(time: selectionStartTime)
        let end = TimeFormatter.shared.playTimeFormat(time: selectionEndTime)
        return "\(start) – \(end)"
    }

    init(bookmark: Bookmark, cues: [TranscriptCue], fullText: String, bookmarkManager: BookmarkManager, existingTitle: String? = nil) {
        self.bookmark = bookmark
        self.cues = cues
        self.fullText = fullText
        self.bookmarkManager = bookmarkManager
        self.bookmarkCueIndex = TranscriptSelectionLogic.bookmarkCueIndex(for: bookmark.time, in: cues) ?? 0

        if let startTime = bookmark.transcriptStartTime,
           let endTime = bookmark.transcriptEndTime,
           let startIdx = TranscriptSelectionLogic.bookmarkCueIndex(for: startTime, in: cues),
           let endIdx = TranscriptSelectionLogic.bookmarkCueIndex(for: endTime, in: cues) {
            let restored = TranscriptSelectionLogic.adjustSelection(startCueIndex: startIdx, endCueIndex: endIdx, cues: cues, fullText: fullText)
            self.startCueIndex = restored?.startCueIndex ?? startIdx
            self.endCueIndex = restored?.endCueIndex ?? endIdx
            self.selectedText = restored?.text ?? ""
        } else {
            let initial = TranscriptSelectionLogic.selectTranscript(
                around: bookmark.time,
                cues: cues,
                fullText: fullText
            )
            self.startCueIndex = initial?.startCueIndex ?? 0
            self.endCueIndex = initial?.endCueIndex ?? min(cues.count - 1, 0)
            self.selectedText = initial?.text ?? ""
        }

        self.isEditing = existingTitle != nil

        if let existingTitle {
            self.bookmarkTitle = existingTitle
        }
    }

    // MARK: - Actions

    func selectCue(at index: Int) {
        guard index >= 0, index < cues.count else { return }
        if index < startCueIndex {
            startCueIndex = index
        } else if index > endCueIndex {
            endCueIndex = index
        } else if index == startCueIndex && startCueIndex < endCueIndex {
            startCueIndex += 1
        } else if index == endCueIndex && endCueIndex > startCueIndex {
            endCueIndex -= 1
        }
        updateSelection()
    }

    func generateTitle() {
        guard bookmarkTitle.isEmpty else { return }
        isGeneratingTitle = true
        Task {
            let title = await BookmarkTitleGenerator.generateTitle(from: selectedText)
            await MainActor.run {
                self.bookmarkTitle = title
                self.isGeneratingTitle = false
            }
        }
    }

    func save() {
        let title = bookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? L10n.bookmarkDefaultTitle : String(title.prefix(maxTitleLength))

        guard let selection = TranscriptSelectionLogic.adjustSelection(
            startCueIndex: startCueIndex,
            endCueIndex: endCueIndex,
            cues: cues,
            fullText: fullText
        ) else {
            router?.selectionSaved(title: finalTitle)
            return
        }

        Task {
            await bookmarkManager.update(title: finalTitle, for: bookmark)
            await bookmarkManager.updateTranscript(
                text: selection.text,
                startTime: selection.startTime,
                endTime: selection.endTime,
                for: bookmark
            )
            await MainActor.run {
                router?.selectionSaved(title: finalTitle)
            }
        }
    }

    func cancel() {
        router?.selectionDismissed()
    }

    // MARK: - Private

    private func updateSelection() {
        guard let selection = TranscriptSelectionLogic.adjustSelection(
            startCueIndex: startCueIndex,
            endCueIndex: endCueIndex,
            cues: cues,
            fullText: fullText
        ) else { return }
        selectedText = selection.text
    }
}
