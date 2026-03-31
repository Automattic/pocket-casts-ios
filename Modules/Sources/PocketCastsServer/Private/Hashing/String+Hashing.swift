import CryptoKit
import Foundation

extension String {
    func insecureSHA1Hash(using encoding: String.Encoding = .utf8) -> String? {
        guard let data = data(using: encoding) else { return nil }

        let hashDigest = CryptoKit.Insecure.SHA1.hash(data: data)
        return hashDigest.compactMap { String(format: "%02hhx", $0) }.joined()
    }
}
