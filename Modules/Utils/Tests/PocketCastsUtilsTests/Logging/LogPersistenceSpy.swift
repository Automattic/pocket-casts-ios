import Foundation

@testable import PocketCastsUtils

final class LogPersistenceSpy: PersistentTextWriting {

    private(set) var textWrittenToLog = false
    private(set) var writeCount: UInt = 0
    private(set) var lastWrittenChunk: String?

    func write(_ text: String) {
        textWrittenToLog = true
        writeCount += 1
        lastWrittenChunk = text
    }

}
