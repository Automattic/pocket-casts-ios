import Foundation

public extension Int {
    var bytes: Int {
        self
    }

    var kilobytes: Int {
        self * 1000
    }

    var megabytes: Int {
        kilobytes * 1000
    }

    var gigabytes: Int {
        megabytes * 1000
    }
}
