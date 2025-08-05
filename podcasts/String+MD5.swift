import CryptoKit

extension String {
    var md5: String {
        let hash = Insecure.MD5.hash(data: self.data(using: .utf8)!)
            .map {String(format: "%02x", $0)}
            .joined()
        return hash
    }
}
