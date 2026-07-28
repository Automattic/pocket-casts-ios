import Foundation

@testable import PocketCastsUtils

struct LogRotatorStub: FileRotating {
    func rotateFile(ifSizeExceeds: Int) {
        // No operation
    }
}
