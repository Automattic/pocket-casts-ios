import Foundation
import AVFoundation

@MainActor
final class TTSViewModel: ObservableObject {
    @Published var text: String = "This morning, I took a walk in the park, and the sound of the birds and the breeze was so pleasant that I stopped for a long time just to listen."
    @Published var nfe: Double = 5
    @Published var voice: TTSService.Voice = Settings.ttsVoice {
        didSet {
            Settings.ttsVoice = voice
        }
    }
    @Published var isGenerating: Bool = false
    @Published var isPlaying: Bool = false
    @Published var errorMessage: String?
    @Published var audioURL: URL?
    @Published var elapsedSeconds: Double?
    @Published var audioSeconds: Double?
    @Published var playbackTime: Double = 0
    @Published var wordHighlights: [WordHighlight] = []

    private var service: TTSService?
    private var player = AudioPlayer()

    var rtfText: String? {
        guard let e = elapsedSeconds, let a = audioSeconds, a > 0 else { return nil }
        return String(format: "RTF %.2fx · %.2fs / %.2fs", e / a, e, a)
    }

    var activeRange: Range<String.Index>? {
        let current = playbackTime
        for highlight in wordHighlights {
            if current >= highlight.start && current <= highlight.end {
                return highlight.range
            }
        }
        if let last = wordHighlights.last, current > last.end {
            return last.range
        }
        return nil
    }

    func startup() {
        do {
            service = try TTSService()
        } catch {
            errorMessage = "Failed to init TTS: \(error.localizedDescription)"
        }
    }

    func generate() {
        guard let service = service else { return }
        isGenerating = true
        errorMessage = nil
        audioURL = nil
        elapsedSeconds = nil
        audioSeconds = nil
        wordHighlights = []
        playbackTime = 0
        Task {
            let tic = Date()
            do {
                let result = try await service.synthesize(text: text, nfe: Int(nfe), voice: voice)
                let elapsed = Date().timeIntervalSince(tic)
                let audio = result.duration
                let highlights = buildHighlights(from: result.timings, text: text)
                await MainActor.run {
                    self.audioURL = result.url
                    self.wordHighlights = highlights
                    self.elapsedSeconds = elapsed
                    self.audioSeconds = audio
                    self.isGenerating = false
                    self.play(url: result.url)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }

    func togglePlay() {
        if isPlaying {
            player.stop()
            isPlaying = false
            playbackTime = 0
        } else if let url = audioURL {
            play(url: url)
        }
    }

    private func play(url: URL) {
        playbackTime = 0
        player.stop()
        player.play(
            url: url,
            onProgress: { [weak self] time in
                DispatchQueue.main.async {
                    self?.playbackTime = time
                }
            },
            onFinish: { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    self?.playbackTime = 0
                }
            }
        )
        isPlaying = true
    }

    private func buildHighlights(from timings: [WordTiming], text: String) -> [WordHighlight] {
        guard let regex = try? NSRegularExpression(pattern: "\\b[^\\s]+\\b") else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        var highlights: [WordHighlight] = []
        let count = min(matches.count, timings.count)

        for idx in 0..<count {
            let match = matches[idx]
            let timing = timings[idx]
            guard
                let range = Range(match.range, in: text)
            else { continue }
            highlights.append(WordHighlight(range: range, start: timing.start, end: timing.end))
        }
        return highlights
    }
}

struct WordHighlight {
    let range: Range<String.Index>
    let start: Double
    let end: Double
}
