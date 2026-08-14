import XCTest

@testable import PocketCastsUtils

final class LogBufferTests: XCTestCase {

    func testLogFlushedWhenThresholdReached() {
        // GIVEN that we have a FileLog with a buffer threshold of 3...
        let fileWriteSpy = LogPersistenceSpy()
        let bufferThreshold: UInt = 3
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: bufferThreshold
        )

        // WHEN we write three log messages...
        for messageNum in 1...bufferThreshold {
            logBuffer.append("Log Message \(messageNum)", date: Date())
        }
        logBuffer.flush()

        // THEN the log messages have been flushed to file persistence.
        XCTAssertTrue(fileWriteSpy.textWrittenToLog)
        XCTAssertEqual(fileWriteSpy.writeCount, 1)
    }

    func testLogNotFlushedBeforeThresholdReached() {
        // GIVEN that we have a FileLog with a buffer threshold of 2...
        let fileWriteSpy = LogPersistenceSpy()
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: 2
        )

        // WHEN we write only one log message...
        logBuffer.append("Log Message", date: Date())

        // THEN the log is not flushed to persistence as the threshold was not reached.
        XCTAssertFalse(fileWriteSpy.textWrittenToLog)
        XCTAssertEqual(fileWriteSpy.writeCount, 0)
    }

    func testFileRotationRequestedWhenFlushing() {
        // GIVEN that we have a FileLog with a low threshold...
        let rotationSpy = LogRotationSpy()
        let logBuffer = LogBuffer(
            logPersistence: LogPersistenceStub(),
            logRotator: rotationSpy,
            bufferThreshold: 1
        )

        // WHEN we exceed the buffer threshold and trigger the log to be flushed...
        logBuffer.append("Log Message", date: Date())
        logBuffer.flush()

        // THEN file rotation is requested.
        XCTAssertTrue(rotationSpy.rotationRequested)
    }

    func testFlushedMessagesSeperatedByNewlines() {
        // GIVEN that we have a FileLog with a low threshold...
        let fileWriteSpy = LogPersistenceSpy()
        let bufferThreshold: UInt = 3
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: bufferThreshold
        )

        // WHEN we write enough messages to trigger a flush...
        for messageNum in 1...bufferThreshold {
            logBuffer.append("Log Message \(messageNum)", date: Date())
        }
        logBuffer.flush()

        // THEN the flushed messages are separated by newlines.
        XCTAssertTrue(fileWriteSpy.textWrittenToLog)
        XCTAssertNotNil(fileWriteSpy.lastWrittenChunk)
        let lineCount = fileWriteSpy.lastWrittenChunk!.split(separator: "\n").count
        XCTAssertEqual(lineCount, 3)
    }

    func testForceFlushFlushesRegardlessOfNumberOfBufferedMessages() {
        // GIVEN that we have a FileLog with a high threshold...
        let fileWriteSpy = LogPersistenceSpy()
        let bufferThreshold: UInt = 10
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: bufferThreshold
        )

        // AND the number of buffered messages is below the threshold...
        let halfBufferThreshold = (bufferThreshold / 2)
        for messageNum in 1...halfBufferThreshold {
            logBuffer.append("Log Message \(messageNum)", date: Date())
        }

        // WHEN we force the FileLog to flush...
        logBuffer.flush()

        // THEN all of the buffered messages are flushed despite being below the threshold.
        XCTAssertTrue(fileWriteSpy.textWrittenToLog)
        XCTAssertEqual(fileWriteSpy.writeCount, 1)
        let linesWrittenCount = fileWriteSpy.lastWrittenChunk!.split(separator: "\n").count
        XCTAssertEqual(UInt(linesWrittenCount), halfBufferThreshold)
    }

    func testFlushedMessagesKeepTheOrderTheyWereLoggedIn() {
        // GIVEN that we have a FileLog with a low threshold...
        let fileWriteSpy = LogPersistenceSpy()
        let bufferThreshold: UInt = 3
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: bufferThreshold
        )

        // WHEN we write enough messages to trigger a flush...
        logBuffer.append("Log Message 1", date: Date())
        logBuffer.append("Log Message 2", date: Date())
        logBuffer.append("Log Message 3", date: Date())
        logBuffer.flush()

        // THEN the flushed messages are in the order they were logged in
        let messages = fileWriteSpy.lastWrittenChunk!.split(separator: "\n")
        XCTAssertTrue(messages[0].contains("Log Message 1"))
        XCTAssertTrue(messages[1].contains("Log Message 2"))
        XCTAssertTrue(messages[2].contains("Log Message 3"))
    }

    func testMessagesLoggedConcurrentlyAreAllFlushed() {
        // GIVEN that we have a FileLog with a threshold no amount of messages will reach...
        let fileWriteSpy = LogPersistenceSpy()
        let messageCount = 500
        let logBuffer = LogBuffer(
            logPersistence: fileWriteSpy,
            logRotator: LogRotatorStub(),
            bufferThreshold: UInt(messageCount) + 1
        )

        // WHEN we write messages from several threads at once...
        DispatchQueue.concurrentPerform(iterations: messageCount) { messageNum in
            logBuffer.append("Log Message \(messageNum)", date: Date())
        }
        logBuffer.flush()

        // THEN every message is flushed in a single chunk.
        XCTAssertEqual(fileWriteSpy.writeCount, 1)
        let lineCount = fileWriteSpy.lastWrittenChunk!.split(separator: "\n").count
        XCTAssertEqual(lineCount, messageCount)
    }
}
