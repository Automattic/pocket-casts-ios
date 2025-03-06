import Foundation

public protocol PCDBQueue {
    func inDatabase(_ block: (PCDatabase) -> Void)

    func inTransaction(_ block: (PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void)

    func close()
}
