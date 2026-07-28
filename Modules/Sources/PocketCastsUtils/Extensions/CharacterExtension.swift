import Foundation

public extension Character {
    func isEmoji() -> Bool {
        Character(UnicodeScalar(UInt32(0x1D000))!) <= self && self <= Character(UnicodeScalar(UInt32(0x1F77F))!)
            || Character(UnicodeScalar(UInt32(0x2100))!) <= self && self <= Character(UnicodeScalar(UInt32(0x26FF))!)
    }
}
