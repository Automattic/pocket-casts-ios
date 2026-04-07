import Foundation

@testable import PocketCastsUtils

final class LogRotationSpy: FileRotating {

    private(set) var rotationRequested = false

    func rotateFile(ifSizeExceeds: Int) {
        rotationRequested = true
    }
}
