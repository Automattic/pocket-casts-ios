import Foundation

@testable import PocketCastsUtils

final class LogPersistenceStub: PersistentTextWriting {

    func write(_ text: String) {
        // No operation
    }

}
