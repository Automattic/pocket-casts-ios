import AVFoundation
import SwiftUI
import XCTest

@testable import podcasts

@MainActor
final class VideoExporterTests: XCTestCase {

    // MARK: - export

    func testExportRendersEveryLoopFrameAndWritesVideoWithAudio() async throws {
        let recorder = FrameRecorder()
        let outputURL = makeTemporaryURL()
        addTeardownBlock { try? FileManager.default.removeItem(at: outputURL) }

        try await VideoExporter.export(view: FrameRecordingView(recorder: recorder), with: try makeParameters(duration: 2), to: outputURL, progress: Progress(totalUnitCount: 100))

        // A 5 second loop at 60 fps, including both the first and the last frame
        XCTAssertEqual(recorder.progressValues, (0...300).map { Double($0) / 300 })

        let asset = AVURLAsset(url: outputURL)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(videoTracks.count, 1)
        XCTAssertEqual(audioTracks.count, 1)
        XCTAssertEqual(duration.seconds, 2, accuracy: 0.1)
    }

    func testCancellingExportStopsRenderingFrames() async throws {
        let recorder = FrameRecorder()
        let outputURL = makeTemporaryURL()
        let parameters = try makeParameters(duration: 2)
        let progress = Progress(totalUnitCount: 100)

        let task = Task {
            try await VideoExporter.export(view: FrameRecordingView(recorder: recorder), with: parameters, to: outputURL, progress: progress)
        }
        recorder.onUpdate = { [recorder] in
            if recorder.progressValues.count == 10 {
                task.cancel()
            }
        }

        do {
            try await task.value
            XCTFail("Expected the export to throw")
        } catch VideoExporter.ExportError.taskCancelled {
            // Expected
        }

        XCTAssertEqual(recorder.progressValues.count, 10)
        XCTAssertTrue(progress.isCancelled)
        XCTAssertFalse(FileManager.default.fileExists(atPath: outputURL.path))
    }

    // MARK: - waitUntilReadyForMoreMediaData

    func testWaitReturnsWhenInputIsReady() async throws {
        let (writer, input) = try makeWriter()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        addTeardownBlock { writer.cancelWriting() }

        try await VideoExporter.waitUntilReadyForMoreMediaData(input, of: writer)

        XCTAssertTrue(input.isReadyForMoreMediaData)
    }

    func testWaitThrowsTaskCancelledWhenWriterIsCancelled() async throws {
        let (writer, input) = try makeWriter()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        writer.cancelWriting()

        do {
            try await VideoExporter.waitUntilReadyForMoreMediaData(input, of: writer)
            XCTFail("Expected the wait to throw")
        } catch VideoExporter.ExportError.taskCancelled {
            // Expected
        }
    }

    func testWaitThrowsExportFailedWhenWriterFails() async throws {
        let existingFileURL = makeTemporaryURL()
        FileManager.default.createFile(atPath: existingFileURL.path, contents: Data())
        addTeardownBlock { try? FileManager.default.removeItem(at: existingFileURL) }

        let (writer, input) = try makeWriter(outputURL: existingFileURL)
        XCTAssertFalse(writer.startWriting())
        XCTAssertEqual(writer.status, .failed)

        do {
            try await VideoExporter.waitUntilReadyForMoreMediaData(input, of: writer)
            XCTFail("Expected the wait to throw")
        } catch VideoExporter.ExportError.exportFailed(let error) {
            XCTAssertEqual((error as? NSError)?.code, AVError.fileAlreadyExists.rawValue)
        }
    }

    func testWaitForInputThatIsNeverReadyStopsWhenTaskIsCancelled() async throws {
        let (writer, input) = try makeWriter()
        XCTAssertFalse(input.isReadyForMoreMediaData)

        let task = Task {
            try await VideoExporter.waitUntilReadyForMoreMediaData(input, of: writer)
        }
        task.cancel()

        do {
            try await task.value
            XCTFail("Expected the wait to throw")
        } catch is CancellationError {
            // Expected
        }
    }

    // MARK: - Helpers

    private func makeTemporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
    }

    private func makeParameters(duration: TimeInterval) throws -> VideoExporter.Parameters {
        let audioURL = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "no-metadata", withExtension: "m4a"))
        return VideoExporter.Parameters(duration: duration,
                                        size: CGSize(width: 32, height: 32),
                                        scale: 1,
                                        episodeAsset: AVURLAsset(url: audioURL),
                                        audioStartTime: .zero,
                                        audioDuration: CMTime(seconds: duration, preferredTimescale: 600),
                                        fileType: .mp4)
    }

    private func makeWriter(outputURL: URL? = nil) throws -> (AVAssetWriter, AVAssetWriterInput) {
        let writer = try AVAssetWriter(outputURL: outputURL ?? makeTemporaryURL(), fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 32,
            AVVideoHeightKey: 32,
        ])
        writer.add(input)
        return (writer, input)
    }
}

@MainActor
private final class FrameRecorder {
    private(set) var progressValues: [Double] = []
    var onUpdate: (() -> Void)?

    func record(_ progress: Double) {
        progressValues.append(progress)
        onUpdate?()
    }
}

private struct FrameRecordingView: AnimatableContent {
    let recorder: FrameRecorder

    var body: some View {
        Color.red
    }

    func update(for progress: Double) {
        recorder.record(progress)
    }
}
