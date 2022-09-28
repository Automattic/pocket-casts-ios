import Foundation

public class AtomicBool {
    private lazy var atomicQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.AtomicQueue")

        return queue
    }()

    private var storageValue = false

    public init() {}

    public var value: Bool {
        get {
            atomicQueue.sync {
                storageValue
            }
        }
        set {
            atomicQueue.sync {
                storageValue = newValue
            }
        }
    }
}
