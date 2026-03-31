import Foundation

public enum DateUtil {
    public static func hasEnoughTimePassed(since date: Date?, time: TimeInterval) -> Bool {
        guard let date = date else { return true }

        return -date.timeIntervalSinceNow > time
    }
}
