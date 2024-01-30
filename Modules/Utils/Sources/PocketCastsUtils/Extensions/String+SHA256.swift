import CryptoKit
import Foundation

extension String {
  public var sha256: String {
    let hashed = SHA256.hash(data: data(using: .utf8) ?? Data())

    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  }
}
