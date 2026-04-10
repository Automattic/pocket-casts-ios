import Foundation

public class SizeFormatter {
    public static let shared = SizeFormatter()
    public var placeholder: String {
        defaultFormat(bytes: 0)
    }

    private lazy var defaultBytesFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false

        return formatter
    }()

    private lazy var fullRangeBytesFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false

        return formatter
    }()

    public func defaultFormat(bytes: Int64) -> String {
        defaultBytesFormatter.string(fromByteCount: bytes)
    }

    public func noDecimalFormat(bytes: Int64) -> String {
        fullRangeBytesFormatter.string(fromByteCount: bytes)
    }
}
