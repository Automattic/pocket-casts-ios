import Foundation

@testable import PocketCastsUtils

final class SerialDispatchMock: DispatchQueueing {
    func async(execute work: @escaping @convention(block) () -> Void) {
        work()
    }
}
