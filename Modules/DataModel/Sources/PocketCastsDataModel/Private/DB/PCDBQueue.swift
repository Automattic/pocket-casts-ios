import Foundation

protocol PCDBQueue {
    func inDatabase(_ block: @escaping (PCDatabase) -> Void)

    func inTransaction(_ block: @escaping (PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void)

    func close()
}
