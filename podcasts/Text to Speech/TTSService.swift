import AVFoundation
import Foundation
import OnnxRuntimeBindings
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

@MainActor
enum TTSLoadingAlert {
    private static var alert: ShiftyLoadingAlert?

    static func show(message: String) {
        guard alert == nil else {
            update(message: message)
            return
        }

        guard let presenter = SceneHelper.rootViewController() else { return }
        let alert = ShiftyLoadingAlert(title: message)
        alert.showAlert(presenter, hasProgress: false, completion: nil)

        if let tabBar = SceneHelper.rootViewController(includeTopMost: false) as? MainTabBarController {
            tabBar.alert = alert
        }

        self.alert = alert
    }

    static func update(message: String) {
        if let tabBar = SceneHelper.rootViewController(includeTopMost: false) as? MainTabBarController {
            tabBar.alert?.title = message
            alert = tabBar.alert
        } else {
            alert?.title = message
        }
    }

    static func dismiss() {
        if let tabBar = SceneHelper.rootViewController(includeTopMost: false) as? MainTabBarController {
            if let tabAlert = tabBar.alert {
                tabAlert.hideAlert(true)
                if tabAlert === alert {
                    alert = nil
                    tabBar.alert = nil
                    return
                }
            }
            tabBar.alert = nil
        }

        alert?.hideAlert(true)
        alert = nil
    }
}

struct WordTiming {
    let word: String
    let start: Double
    let end: Double
}

final class TTSService {
    enum Voice { case male, female }

    private let env: ORTEnv
    private let textToSpeech: TextToSpeech
    private let bundleOnnxDir: String
    private let sampleRate: Int

    init() throws {
        bundleOnnxDir = try Self.locateOnnxDirInBundle()
        env = try ORTEnv(loggingLevel: .warning)
        textToSpeech = try loadTextToSpeech(bundleOnnxDir, false, env)
        sampleRate = textToSpeech.sampleRate
    }

    func synthesize(text: String, nfe: Int, voice: Voice) async throws -> (url: URL, timings: [WordTiming], duration: Double) {
        // Load style for the selected voice
        let styleURL = try Self.locateVoiceStyleURL(voice: voice)
        let style = try loadVoiceStyle([styleURL.path], verbose: false)
        FileLog.shared.addMessage("TTSService: starting streaming synth nfe \(nfe)")

        // 2) Synthesize via packed TextToSpeech component
        let (wav, duration, chunkOutputs) = try textToSpeech.call(text, style, nfe)
        let audioSeconds = Double(duration)
        let wavLenSample = min(Int(Double(sampleRate) * audioSeconds), wav.count)
        let wavOut = Array(wav[0..<wavLenSample])

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("supertonic_tts_\(UUID().uuidString).wav")
        try writeWavFile(tmpURL.path, wavOut, sampleRate)

        let timings = computeTimings(from: chunkOutputs)
        return (tmpURL, timings, audioSeconds)
    }

    /// Fetches the icon for episode artwork - tries Diffbot icon URL first, then falls back to favicon
    private func fetchIcon(iconURL: String?, fallbackURL: String) async -> UIImage? {
        // Try Diffbot icon first if provided
        if let iconURLString = iconURL, !iconURLString.isEmpty {
            FileLog.shared.addMessage("TTSService: attempting to fetch Diffbot icon from: \(iconURLString)")

            guard let iconURL = URL(string: iconURLString) else {
                FileLog.shared.addMessage("TTSService: invalid Diffbot icon URL: \(iconURLString)")
                return await fetchFallbackIcon(from: fallbackURL)
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: iconURL)

                if let httpResponse = response as? HTTPURLResponse {
                    FileLog.shared.addMessage("TTSService: Diffbot icon response status: \(httpResponse.statusCode), content-type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown")")
                }

                FileLog.shared.addMessage("TTSService: received \(data.count) bytes for Diffbot icon")

                if let image = UIImage(data: data) {
                    FileLog.shared.addMessage("TTSService: successfully created UIImage from Diffbot icon, size: \(image.size)")
                    return image
                } else {
                    FileLog.shared.addMessage("TTSService: failed to create UIImage from Diffbot icon data")
                }
            } catch {
                FileLog.shared.addMessage("TTSService: error fetching Diffbot icon: \(error.localizedDescription)")
            }
        } else {
            FileLog.shared.addMessage("TTSService: no Diffbot icon URL provided, using fallback")
        }

        return await fetchFallbackIcon(from: fallbackURL)
    }

    /// Fetches favicon as fallback artwork
    private func fetchFallbackIcon(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString),
              let host = url.host else {
            FileLog.shared.addMessage("TTSService: invalid fallback URL: \(urlString)")
            return nil
        }

        // Build favicon URLs to try
        var faviconURLs = [
            "https://\(host)/favicon.ico",
            "https://\(host)/apple-touch-icon.png"
        ]

        // If host doesn't start with www, also try with www prefix
        if !host.hasPrefix("www.") {
            faviconURLs.append("https://www.\(host)/favicon.ico")
        }

        for faviconURLString in faviconURLs {
            guard let faviconURL = URL(string: faviconURLString) else { continue }

            do {
                let (data, _) = try await URLSession.shared.data(from: faviconURL)
                if let image = UIImage(data: data) {
                    FileLog.shared.addMessage("TTSService: fetched favicon from \(faviconURLString)")
                    return image
                }
            } catch {
                // Try next URL
                continue
            }
        }

        FileLog.shared.addMessage("TTSService: failed to fetch icon from any location")
        return nil
    }

    /// Streams synthesis to disk while beginning playback through `PlaybackManager` as soon as the first buffer is available.
    /// Returns the saved user episode and timing metadata once generation completes.
    func synthesizeStreaming(text: String, nfe: Int, voice: Voice, title: String, url: String, iconURL: String?) async throws -> (episode: UserEpisode, timings: [WordTiming], duration: Double) {
        let styleURL = try Self.locateVoiceStyleURL(voice: voice)
        let style = try loadVoiceStyle([styleURL.path], verbose: false)

        let uuid = UUID().uuidString
        let outputPath = DownloadManager.shared.pathForUrl(fileUrl: URL(fileURLWithPath: "tts.caf"), uuid: uuid)
        let outputURL = URL(fileURLWithPath: outputPath)
        let fm = FileManager.default
        try fm.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: outputURL.path) {
            try? fm.removeItem(at: outputURL)
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)

        guard let format else {
            throw NSError(domain: "TTS", code: -200, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"])
        }

        var wavSettings = format.settings
        wavSettings[AVFormatIDKey] = kAudioFormatLinearPCM
        wavSettings[AVLinearPCMIsFloatKey] = true
        wavSettings[AVLinearPCMIsBigEndianKey] = false
        wavSettings[AVLinearPCMIsNonInterleaved] = true
        let writer = try AVAudioFile(forWriting: outputURL, settings: wavSettings, commonFormat: .pcmFormatFloat32, interleaved: false)
        FileLog.shared.addMessage("TTSService: opened writer at \(outputURL.path)")
        let tempEpisode = TTSTemporaryEpisode(uuid: uuid, title: title, fileURL: outputURL, duration: 0, fileType: "audio/caf")

        var audioSeconds: Double = 0
        var chunkOutputs: [TextToSpeech.ChunkedAudio] = []
        var startedPlayback = false
        var chunksBeforePlayback = 0
        let minChunksBeforePlayback = 1
        var dismissedLoadingAlert = false

        let result = try textToSpeech.call(text, style, nfe, onChunk: { chunk in
            do {
                try writer.write(from: chunk.buffer)
            } catch {
                FileLog.shared.addMessage("TTSService: writer failed \(error)")
            }

            audioSeconds += Double(chunk.duration)
            chunkOutputs.append(chunk)
            chunksBeforePlayback += 1

            if !startedPlayback && chunksBeforePlayback >= minChunksBeforePlayback {
                tempEpisode.duration = audioSeconds
                startedPlayback = true
                // Small delay to ensure chunks are written to disk before playback begins
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    PlaybackManager.shared.load(episode: tempEpisode, autoPlay: true, overrideUpNext: false)
                    // Notify initial duration is set
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDurationChanged, object: tempEpisode.uuid)
                    if !dismissedLoadingAlert {
                        dismissedLoadingAlert = true
                        TTSLoadingAlert.dismiss()
                    }
                }
            } else if startedPlayback {
                tempEpisode.duration = audioSeconds
                // Notify that duration has changed so UI can update
                DispatchQueue.main.async {
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDurationChanged, object: tempEpisode.uuid)
                }
            } else {
                // Still buffering before playback
                tempEpisode.duration = audioSeconds
            }
        })

        FileLog.shared.addMessage("TTSService: synthesis complete duration \(result.duration) temp seconds \(audioSeconds)")
        let timings = computeTimings(from: chunkOutputs)
        let fileSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0

        // Fetch icon for artwork - prefer Diffbot icon if available, fallback to favicon
        let artwork = await fetchIcon(iconURL: iconURL, fallbackURL: url)

        let episode = try await MainActor.run {
            try UserEpisodeManager.addUserEpisode(
                uuid: uuid,
                title: title,
                localFileUrl: outputURL,
                artwork: artwork,
                color: 1,
                fileSize: fileSize,
                duration: Double(result.duration)
            )
        }

        await MainActor.run {
            PlaybackManager.shared.queue.replaceTemporaryEpisode(with: episode)
            PlaybackManager.shared.queue.nowPlayingEpisodeChanged()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.currentlyPlayingEpisodeUpdated)
        }

        return (episode, timings, Double(result.duration))
    }

    private func computeTimings(from chunks: [TextToSpeech.ChunkedAudio]) -> [WordTiming] {
        var timings: [WordTiming] = []
        for chunk in chunks {
            let words = Self.extractWords(from: chunk.text)
            guard !words.isEmpty else { continue }

            let weights = words.map { max(1, $0.replacingOccurrences(of: "[^\\w]", with: "", options: .regularExpression).count) }
            let totalWeight = max(1, weights.reduce(0, +))

            var cursor = Double(chunk.startTime)
            for (word, weight) in zip(words, weights) {
                let proportion = Double(weight) / Double(totalWeight)
                let wordDuration = Double(chunk.duration) * proportion
                let start = cursor
                let end = cursor + wordDuration
                timings.append(WordTiming(word: word, start: start, end: end))
                cursor = end
            }
        }
        return timings
    }

    private static func extractWords(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "\\b[^\\s]+\\b") else {
            return text.split(separator: " ").map(String.init)
        }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match in
            let range = match.range
            guard range.location != NSNotFound else { return nil }
            return ns.substring(with: range)
        }
    }

    // MARK: - Resource location helpers
    private static func locateOnnxDirInBundle() throws -> String {
        let bundle = Bundle.main
        let fm = FileManager.default

        func dirHasRequiredFiles(_ dir: URL) -> Bool {
            let required = [
                "tts.json",
                "duration_predictor.onnx",
                "text_encoder.onnx",
                "vector_estimator.onnx",
                "vocoder.onnx"
            ]
            return required.allSatisfy { fm.fileExists(atPath: dir.appendingPathComponent($0).path) }
        }

        var candidates: [URL] = []
        if let dir = bundle.resourceURL?.appendingPathComponent("onnx", isDirectory: true) { candidates.append(dir) }
        if let dir = bundle.resourceURL?.appendingPathComponent("assets/onnx", isDirectory: true) { candidates.append(dir) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: "onnx") { candidates.append(url.deletingLastPathComponent()) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: "assets/onnx") { candidates.append(url.deletingLastPathComponent()) }
        if let url = bundle.url(forResource: "tts", withExtension: "json", subdirectory: nil) { candidates.append(url.deletingLastPathComponent()) }
        if let root = bundle.resourceURL { candidates.append(root) }

        for dir in candidates {
            if dirHasRequiredFiles(dir) { return dir.path }
        }
        throw NSError(
            domain: "TTS",
            code: -100,
            userInfo: [NSLocalizedDescriptionKey: "Could not find the onnx directory in the bundle. Please make sure the onnx folder (as a folder reference) is included in Copy Bundle Resources in Xcode."]
        )
    }

    private static func locateVoiceStyleURL(voice: Voice) throws -> URL {
        // Prefer M1/F1 defaults; search common subdirectories
        let fileName = (voice == .male) ? "M3" : "F3"
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "voice_styles"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "assets/voice_styles"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: nil)
        ]
        for url in candidates {
            if let url = url { return url }
        }
        // Fallback: scan folders if needed
        if let folder1 = bundle.resourceURL?.appendingPathComponent("voice_styles", isDirectory: true) {
            let file = folder1.appendingPathComponent("\(fileName).json")
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        if let folder2 = bundle.resourceURL?.appendingPathComponent("assets/voice_styles", isDirectory: true) {
            let file = folder2.appendingPathComponent("\(fileName).json")
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        throw NSError(
            domain: "TTS",
            code: -102,
            userInfo: [NSLocalizedDescriptionKey: "Could not find the voice style JSON (\(fileName).json) in the bundle. Ensure voice_styles folder is included in Copy Bundle Resources."]
        )
    }
}
