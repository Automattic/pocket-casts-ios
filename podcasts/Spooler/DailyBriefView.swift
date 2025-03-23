import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import AVFoundation

private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

struct DailyBriefView: View {
    @State private var selectedDuration = "Short"
    @State private var isShowingCustomOptions = false
    @State private var isShowingPreferences = false
    @State private var customServices: [String: String] = [:]
    @State private var segmentFiles: [URL] = []
    @State private var currentSegmentIndex = 0
    @State private var briefSegments: [BriefSegment] = []
    @State private var progressText: String?
    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var segmentDurations: [Double] = []
    @State private var totalSegments = 0
    @State private var notificationObserver: NSObjectProtocol?
    @State private var preferences = Preferences(
        selectedOptions: [
            .location: ["San Francisco"],
            .news: ["General"],
            .sports: ["General"],
            .stocks: ["AAPL", "GOOG"],
            .emailNewsletters: ["Morning Brew"]
        ],
        birthday: nil
    )

    private let durations = ["Short", "Medium", "Long", "Custom"]
    @Environment(\.safeAreaInsets) var safeAreaInsets

    var body: some View {
        VStack(spacing: 24) {
            // Duration options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(durations, id: \.self) { duration in
                    DurationCell(
                        title: duration,
                        isSelected: selectedDuration == duration
                    )
                    .onTapGesture {
                        if duration == "Custom" {
                            isShowingCustomOptions = true
                        }
                        selectedDuration = duration
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)

            // Progress text
            if let text = progressText {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(ThemeColor.primaryText02()))
                    .padding(.top, 8)
            }

            Spacer()
                .frame(maxHeight: 100) // Limit spacer height

            VStack(spacing: 16) {
                // Play button
                Button(action: playTapped) {
                    Text(isLoading ? "Loading..." : (isPlaying ? "Stop" : "Play"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(ThemeColor.primaryInteractive01()))
                        .cornerRadius(22)
                }
                .disabled(isLoading)
                .padding(.horizontal)

                // Reset button
                Button(action: resetTapped) {
                    Text("Reset")
                        .font(.system(size: 15))
                        .foregroundColor(Color(ThemeColor.primaryInteractive01()))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, safeAreaInsets.bottom > 0 ? 16 : 32)

            if safeAreaInsets.bottom > 0 {
                Spacer()
                    .frame(height: safeAreaInsets.bottom)
            }
        }
        .navigationTitle("Your Daily Brief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Color(ThemeColor.primaryInteractive01()))
                }
            }
        }
        .sheet(isPresented: $isShowingCustomOptions) {
            CustomOptionsView { services in
                customServices = services
            }
        }
        .sheet(isPresented: $isShowingPreferences) {
            PreferencesView(preferences: preferences) { newPreferences in
                preferences = newPreferences
            }
        }
        .edgesIgnoringSafeArea([.bottom])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(ThemeColor.primaryUi01()))
        .onDisappear {
            // Clean up notification observer when view disappears
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
                notificationObserver = nil
            }
        }

    }

    private func playTapped() {
        if isPlaying {
            isPlaying = false
            PlaybackManager.shared.pause()
            return
        }

        Task {
            do {
                try await fetchAndPlayBrief()
            } catch {
                isLoading = false
                progressText = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func resetTapped() {
        selectedDuration = "Short"
        customServices = [:]
        isPlaying = false
        PlaybackManager.shared.pause()
        progressText = nil
    }

    private func fetchAndPlayBrief() async throws {
        isLoading = true

        do {
            // Fetch brief from API
            let response = try await fetchBrief()

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
            self.segmentFiles = segmentFiles
            self.segmentDurations = segmentDurations
            self.currentSegmentIndex = 0
            self.totalSegments = segmentFiles.count
            self.briefSegments = response.data

            isLoading = false

            // Update progress text with segments
            updateProgressText(with: response.data)

            // Setup notification observer for playback completion
            setupPlaybackCompletionObserver()

            // Play the first segment only
            try await playSegment(at: 0)

        } catch {
            isLoading = false
            progressText = "Error: \(error.localizedDescription)"
        }
    }

    private func fetchBrief() async throws -> SpoolerBriefResponse {
        // Get selected duration
        let briefDuration = BriefDuration(rawValue: selectedDuration.lowercased()) ?? .short

        // Get location if available
        var location: (latitude: Double, longitude: Double)?
        if let locationOptions = preferences.selectedOptions[.location] {
            let selectedLocation = locationOptions.first
            switch selectedLocation {
            case "Current Location":
                // Use San Francisco as default for now
                location = (37.7749, -122.4194)
            case "Belmont":
                location = (37.51575, -122.2950406)
            case "San Francisco":
                location = (37.7749, -122.4194)
            case "New York":
                location = (40.7128, -74.0060)
            case "London":
                location = (51.5074, -0.1278)
            case "Berlin":
                location = (52.5200, 13.4050)
            default:
                break
            }
        }

        // Build services array based on preferences or custom services
        var services: [String] = []

        if selectedDuration == "Custom" {
            // Use custom services
            services = customServices.map { "\($0.key) \($0.value)" }
        } else {
            // Use preferences
            if let locationOptions = preferences.selectedOptions[.location] {
                services.append(contentsOf: locationOptions.map { "Location \($0)" })
            }
            if let newsOptions = preferences.selectedOptions[.news] {
                services.append(contentsOf: newsOptions.map { "News \($0)" })
            }
            if let stocksOptions = preferences.selectedOptions[.stocks] {
                services.append(contentsOf: stocksOptions.map { "Stock \($0)" })
            }
            if let sportsOptions = preferences.selectedOptions[.sports] {
                services.append(contentsOf: sportsOptions.map { "Sports \($0)" })
            }
            if let newsletterOptions = preferences.selectedOptions[.emailNewsletters] {
                services.append(contentsOf: newsletterOptions.map { "Newsletter \($0)" })
            }
        }

        // Fetch the brief
        return try await SpoolerAPIClient.shared.fetchBrief(
            duration: briefDuration,
            location: location,
            birthday: preferences.birthday?.formatted(date: .long, time: .omitted),
            services: services
        )
    }

    private func playSegment(at index: Int) async throws {
        // Create a temporary UserEpisode for playback
        let uuid = UUID().uuidString

        // Determine which file to use (custom file or segment file)
        let segmentFile: URL
        if index < segmentFiles.count {
            segmentFile = segmentFiles[index]
        } else {
            print("Invalid segment index: \(index), total segments: \(segmentFiles.count)")
            throw NSError(domain: "com.pocketcasts.spooler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid segment index"])
        }

        // Ensure we have a valid segment file
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
            title: "Daily Brief",
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

        // Play using PlaybackManager
        PlaybackManager.shared.load(episode: briefEpisode, autoPlay: true, overrideUpNext: true)

        // Debug - Log playback start
        print("Starting playback of episode with UUID: \(briefEpisode.uuid)")
        print("Episode title: \(briefEpisode.title)")
        print("Episode duration: \(briefEpisode.duration) seconds")
        print("Episode file type: \(briefEpisode.fileType)")

        isPlaying = true
    }

    private func setupPlaybackCompletionObserver() {
        print("Setting up playback completion observers")

        // Use the correct notification name for playback ended/completed
        notificationObserver = NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackEnded, object: nil, queue: .main) { [self] _ in
            print("Received playbackEnded notification")
            self.playbackCompleted()
        }

        // Also observe for track changes which can happen when a track finishes
        NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackTrackChanged, object: nil, queue: .main) { [self] _ in
            print("Received playbackTrackChanged notification")
            // Check if we're still playing - if not, it means the track ended
            if !PlaybackManager.shared.playing() {
                print("PlaybackManager is no longer playing - treating as track completion")
                self.playbackCompleted()
            } else {
                print("PlaybackManager is still playing - not treating as completion")
            }
        }

        // Add one more observer for playback paused which might happen at the end
        NotificationCenter.default.addObserver(forName: Constants.Notifications.playbackPaused, object: nil, queue: .main) { [self] _ in
            print("Received playbackPaused notification")
            // If we're at the end of a track, this might be a completion
            if let episode = PlaybackManager.shared.currentEpisode(),
               episode.duration > 0 &&
               abs(episode.duration - PlaybackManager.shared.currentTime()) < 1.0 {
                print("Paused at end of track - treating as completion")
                self.playbackCompleted()
            }
        }
    }

    private func playbackCompleted() {
        // Handle playback completion
        print("Playback completed for segment \(currentSegmentIndex)")

        // Check if there are more segments to play
        if currentSegmentIndex < totalSegments - 1 {
            currentSegmentIndex += 1
            print("Playing next segment: \(currentSegmentIndex) of \(totalSegments)")

            // Play the next segment
            Task {
                do {
                    try await playSegment(at: currentSegmentIndex)
                } catch {
                    print("ERROR playing next segment \(currentSegmentIndex): \(error)")
                    // Try to continue with the next segment if there is one
                    if currentSegmentIndex < totalSegments - 1 {
                        currentSegmentIndex += 1
                        print("Attempting to skip to segment: \(currentSegmentIndex)")
                        try? await playSegment(at: currentSegmentIndex)
                    } else {
                        print("No more segments to play after error")
                        isPlaying = false
                    }
                }
            }
        } else {
            print("All segments completed")
            isPlaying = false
        }
    }

    private func updateProgressText(with briefSegments: [BriefSegment]) {
        // Update progress text with segments
        progressText = briefSegments.map { $0.type }.joined(separator: " • ")
    }
}

struct DurationCell: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(ThemeColor.primaryUi02()))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color(isSelected ? ThemeColor.primaryInteractive01() : ThemeColor.primaryUi05()),
                            lineWidth: 2
                        )
                )

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(ThemeColor.primaryText01()))
        }
        .frame(height: 56)
        .background(
            isSelected ? Color(ThemeColor.primaryInteractive01()).opacity(0.1) : Color.clear
        )
    }
}

#Preview {
    DailyBriefView()
}
