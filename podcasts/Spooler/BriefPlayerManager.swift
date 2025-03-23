import Foundation
import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

// MARK: - Brief Player Manager
class BriefPlayerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var progressText: String?
    @Published var currentSegmentIndex = 0
    @Published var totalSegments = 0

    // MARK: - Private Properties
    private var segmentFiles: [URL] = []
    private var segmentDurations: [Double] = []
    private var briefSegments: [BriefSegment] = []
    private var notificationObserver: NSObjectProtocol?

    // MARK: - Initialization
    init() {
        setupPlaybackCompletionObserver()
    }

    deinit {
        removeNotificationObservers()
    }

    // MARK: - Public Methods
    func playBrief(duration: BriefDuration, customServices: [String: String] = [:]) async throws {
        await MainActor.run {
            isLoading = true
            progressText = "Loading brief..."
        }

        do {
            // Fetch brief from API
            let response = try await fetchBrief(duration: duration, customServices: customServices)

            // Create separate files for each segment
            var segmentFiles: [URL] = []
            var segmentDurations: [Double] = []
            print("Creating individual segment files:")

            var totalDuration: Double = 0
            for (index, segment) in response.data.enumerated() {
                let (data, _) = try await URLSession.shared.data(from: segment.url)

                // Create a temporary file for each segment
                let segmentFile = FileManager.default.temporaryDirectory.appendingPathComponent("segment_\(index)_\(UUID().uuidString).mp3")
                try data.write(to: segmentFile)
                segmentFiles.append(segmentFile)

                // Add segment duration (convert from milliseconds to seconds)
                var segmentDuration: Double = 0
                if let duration = segment.duration {
                    // The API returns duration in milliseconds, convert to seconds
                    segmentDuration = Double(duration) / 1000.0
                    totalDuration += segmentDuration
                    print("Segment \(index) duration: \(duration)ms = \(segmentDuration)s")
                } else {
                    // If no duration provided, estimate based on audio data size
                    segmentDuration = Double(data.count) / (128 * 1024) // 128KB per second
                    totalDuration += segmentDuration
                    print("No duration for segment \(index), estimated \(segmentDuration) seconds based on size")
                }
                segmentDurations.append(segmentDuration)

                print("Created segment file \(index) at: \(segmentFile.path)")
            }

            // Store segment files for later playback
            await MainActor.run {
                self.segmentFiles = segmentFiles
                self.segmentDurations = segmentDurations
                self.currentSegmentIndex = 0
                self.totalSegments = segmentFiles.count
                self.briefSegments = response.data
                self.isLoading = false

                // Update progress text with segments
                self.updateProgressText(with: response.data)
            }

            // Play the first segment only
            try await playSegment(at: 0)

        } catch {
            await MainActor.run {
                isLoading = false
                progressText = "Error: \(error.localizedDescription)"
            }
            throw error
        }
    }

    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            resumePlayback()
        }
    }

    func pausePlayback() {
        Task { @MainActor in
            isPlaying = false
        }
        PlaybackManager.shared.pause()
    }

    func resumePlayback() {
        if !isPlaying {
            Task { @MainActor in
                isPlaying = true
            }
            PlaybackManager.shared.play()
        }
    }

    func resetPlayback() {
        pausePlayback()
        Task { @MainActor in
            progressText = nil
            currentSegmentIndex = 0
            totalSegments = 0
            segmentFiles = []
            segmentDurations = []
            briefSegments = []
        }
    }

    // MARK: - Private Methods
    private func fetchBrief(duration: BriefDuration, customServices: [String: String]) async throws -> SpoolerBriefResponse {
        // Prepare request parameters
        var params: [String: Any] = [
            "duration": duration.rawValue
        ]

        // Add custom services if any
        if !customServices.isEmpty {
            params["services"] = customServices
        }

        // Request brief from API
        return try await SpoolerAPIClient.shared.fetchBrief(
            duration: duration,
            location: nil, // Use default location
            birthday: nil,
            services: customServices.map { "\($0.key) \($0.value)" }
        )
    }

    private func playSegment(at index: Int) async throws {
        // Create a temporary UserEpisode for playback
        let uuid = UUID().uuidString

        // Determine which file to use
        let segmentFile: URL
        if index < segmentFiles.count {
            segmentFile = segmentFiles[index]
        } else {
            print("Invalid segment index: \(index), total segments: \(segmentFiles.count)")
            throw NSError(domain: "com.pocketcasts.spooler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid segment index"])
        }

        // Ensure file exists
        guard FileManager.default.fileExists(atPath: segmentFile.path) else {
            print("Segment file does not exist at path: \(segmentFile.path)")
            throw NSError(domain: "com.pocketcasts.spooler", code: 2, userInfo: [NSLocalizedDescriptionKey: "Segment file not found"])
        }

        // Get file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: segmentFile.path)
        let fileSize = fileAttributes[.size] as? UInt64 ?? 0

        print("Playing segment \(index) from file: \(segmentFile.path), size: \(fileSize) bytes")

        // Create the UserEpisode with the downloaded file
        let briefEpisode = try UserEpisodeManager.addUserEpisode(
            uuid: uuid,
            title: "Daily Brief Segment \(index + 1)",
            localFileUrl: segmentFile,
            artwork: nil,
            color: 1,
            fileSize: Int(fileSize),
            duration: segmentDurations[index]
        )

        // Manually set the file type to ensure it's correct
        briefEpisode.fileType = "audio/mp3"

        // Mark as downloaded to ensure the player uses the local file
        briefEpisode.episodeStatus = DownloadStatus.downloaded.rawValue

        // Set the download task ID to help identify the file
        briefEpisode.downloadTaskId = uuid

        // Set the direct file URL - use the absoluteString which includes the file:// scheme
        briefEpisode.downloadUrl = segmentFile.absoluteString
        print("Setting downloadUrl to: \(segmentFile.absoluteString)")

        // Move the file to the proper location where the app expects it
        let destinationPath = DownloadManager.shared.pathForEpisode(briefEpisode)
        print("Moving file to destination path: \(destinationPath)")

        do {
            // Create directory if it doesn't exist
            let destinationDirectory = URL(fileURLWithPath: destinationPath).deletingLastPathComponent().path
            try FileManager.default.createDirectory(atPath: destinationDirectory, withIntermediateDirectories: true, attributes: nil)

            // Move the file to the expected location
            if FileManager.default.fileExists(atPath: destinationPath) {
                try FileManager.default.removeItem(atPath: destinationPath)
            }
            try FileManager.default.moveItem(at: segmentFile, to: URL(fileURLWithPath: destinationPath))
            print("File successfully moved to: \(destinationPath)")
            print("File exists at destination: \(FileManager.default.fileExists(atPath: destinationPath))")
        } catch {
            print("Error moving file: \(error)")
        }

        // Set additional properties to ensure playback works
        briefEpisode.playingStatus = PlayingStatus.notPlayed.rawValue
        briefEpisode.playedUpTo = 0

        // Save the episode with all properties set
        DataManager.sharedManager.save(episode: briefEpisode)

        // Debug - Log playback attempt
        print("About to start playback of episode with UUID: \(briefEpisode.uuid)")
        print("Episode status: \(briefEpisode.episodeStatus)")
        print("Episode playing status: \(briefEpisode.playingStatus)")
        print("Episode path: \(DownloadManager.shared.pathForEpisode(briefEpisode))")
        print("File exists: \(FileManager.default.fileExists(atPath: DownloadManager.shared.pathForEpisode(briefEpisode)))")

        // Load and play the episode using PlaybackManager
        PlaybackManager.shared.load(episode: briefEpisode, autoPlay: true, overrideUpNext: true)

        // Debug - Log playback start
        print("Started playback of segment \(index)")
        print("Episode title: \(briefEpisode.title)")
        print("Episode duration: \(briefEpisode.duration) seconds")
        print("Episode file type: \(briefEpisode.fileType)")

        await MainActor.run {
            isPlaying = true
        }
    }

    private func updateProgressText(with briefSegments: [BriefSegment]) {
        // Update progress text with segments
        Task { @MainActor in
            progressText = briefSegments.map { $0.type }.joined(separator: " • ")
        }
    }

    private func setupPlaybackCompletionObserver() {
        print("Setting up playback completion observers")

        // Use the correct notification name for playback ended/completed
        notificationObserver = NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackEnded, object: nil, queue: .main) { [weak self] _ in
            print("Received playbackEnded notification")
            self?.handlePlaybackCompleted()
        }

        // Also observe for track changes which can happen when a track finishes
        NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackTrackChanged, object: nil, queue: .main) { [weak self] _ in
            print("Received playbackTrackChanged notification")
            // Check if we're still playing - if not, it means the track ended
            if !PlaybackManager.shared.playing() {
                print("PlaybackManager is no longer playing - treating as track completion")
                self?.handlePlaybackCompleted()
            } else {
                print("PlaybackManager is still playing - not treating as completion")
            }
        }

        // Add one more observer for playback paused which might happen at the end
        NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackPaused, object: nil, queue: .main) { [weak self] _ in
            print("Received playbackPaused notification")
            // If we're at the end of a track, this might be a completion
            if let episode = PlaybackManager.shared.currentEpisode(),
               episode.duration > 0 &&
               abs(episode.duration - PlaybackManager.shared.currentTime()) < 1.0 {
                print("Paused at end of track - treating as completion")
                self?.handlePlaybackCompleted()
            }
        }
    }

    private func removeNotificationObservers() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }

        // Remove other observers
        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.playbackTrackChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.playbackPaused, object: nil)
    }

    private func handlePlaybackCompleted() {
        // Handle playback completion
        print("Playback completed for segment \(currentSegmentIndex)")

        // Move to the next segment if available
        Task {
            do {
                // Increment the segment index
                await MainActor.run {
                    currentSegmentIndex += 1
                }

                // Check if there are more segments to play
                if currentSegmentIndex < totalSegments {
                    print("Playing next segment: \(currentSegmentIndex)")
                    try await playSegment(at: currentSegmentIndex)
                } else {
                    print("All segments completed")
                    await MainActor.run {
                        isPlaying = false
                    }
                }
            } catch {
                print("Error playing next segment: \(error)")

                // Try to recover by moving to the next segment
                await MainActor.run {
                    currentSegmentIndex += 1
                }

                if currentSegmentIndex < totalSegments {
                    print("Attempting to play next segment after error: \(currentSegmentIndex)")
                    do {
                        try await playSegment(at: currentSegmentIndex)
                    } catch {
                        print("Failed to play next segment after error: \(error)")
                        await MainActor.run {
                            isPlaying = false
                        }
                    }
                } else {
                    print("No more segments to play after error")
                    await MainActor.run {
                        isPlaying = false
                    }
                }
            }
        }
    }
}
