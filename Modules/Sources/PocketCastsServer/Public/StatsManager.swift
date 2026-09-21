import Foundation
import PocketCastsDataModel
import PocketCastsUtils

public class StatsManager {
    public static let shared = StatsManager()

    private struct Times {
        var savedDynamicSpeed = -1 as TimeInterval
        var savedVariableSpeed = -1 as TimeInterval
        var totalListenedTo = -1 as TimeInterval
        var totalSkipped = -1 as TimeInterval
        var savedAutoSkipping = -1 as TimeInterval

        var isSynced = true
    }

    private let times = Mutex(Times())

    public init() {
        if UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.statsStartDate) as? Date == nil {
            UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.statsStartDate)
            UserDefaults.standard.synchronize()
        }

        times.withLock { times in
            times.savedDynamicSpeed = timeForKey(ServerConstants.UserDefaults.statsDynamicSpeedSeconds)
            times.savedVariableSpeed = timeForKey(ServerConstants.UserDefaults.statsVariableSpeed)
            times.totalListenedTo = timeForKey(ServerConstants.UserDefaults.statsListenedTo)
            times.totalSkipped = timeForKey(ServerConstants.UserDefaults.statsSkipped)
            times.savedAutoSkipping = timeForKey(ServerConstants.UserDefaults.statsAutoSkip)
        }
    }

    func updateStatsIfNeeded(savedDynamicSpeed: TimeInterval, savedVariableSpeed: TimeInterval, totalListenedTo: TimeInterval, totalSkipped: TimeInterval, savedAutoSkipping: TimeInterval) {
        let minimumStatsChangeToUpdate: TimeInterval = 100

        times.withLock { times in
            if savedDynamicSpeed - times.savedDynamicSpeed > minimumStatsChangeToUpdate {
                FileLog.shared.addMessage("[StatsManager] Changing savedDynamicSpeed from \(times.savedDynamicSpeed) to \(savedDynamicSpeed)")
                times.savedDynamicSpeed = savedDynamicSpeed
            }

            if savedVariableSpeed - times.savedVariableSpeed > minimumStatsChangeToUpdate {
                FileLog.shared.addMessage("[StatsManager] Changing savedVariableSpeed from \(times.savedVariableSpeed) to \(savedVariableSpeed)")
                times.savedVariableSpeed = savedVariableSpeed
            }

            if totalListenedTo - times.totalListenedTo > minimumStatsChangeToUpdate {
                FileLog.shared.addMessage("[StatsManager] Changing totalListenedTo from \(times.totalListenedTo) to \(totalListenedTo)")
                times.totalListenedTo = totalListenedTo
            }

            if totalSkipped - times.totalSkipped > minimumStatsChangeToUpdate {
                FileLog.shared.addMessage("[StatsManager] Changing totalSkipped from \(times.totalSkipped) to \(totalSkipped)")
                times.totalSkipped = totalSkipped
            }

            if savedAutoSkipping - times.savedAutoSkipping > minimumStatsChangeToUpdate {
                FileLog.shared.addMessage("[StatsManager] Changing savedAutoSkipping from \(times.savedAutoSkipping) to \(savedAutoSkipping)")
                times.savedAutoSkipping = savedAutoSkipping
            }
        }

        persistTimes()
    }

    // MARK: - dynamic speed

    public func timeSavedDynamicSpeed() -> TimeInterval {
        times.withLock { $0.savedDynamicSpeed }
    }

    public func addTimeSavedDynamicSpeed(_ seconds: TimeInterval) {
        times.withLock { times in
            times.savedDynamicSpeed += max(seconds, 0)
            times.isSynced = false
        }
    }

    // MARK: - variable speed

    public func timeSavedVariableSpeed() -> TimeInterval {
        times.withLock { $0.savedVariableSpeed }
    }

    public func addTimeSavedVariableSpeed(_ seconds: TimeInterval) {
        times.withLock { times in
            times.savedVariableSpeed += max(seconds, 0)
            times.isSynced = false
        }
    }

    // MARK: - total listened

    public func totalListeningTime() -> TimeInterval {
        times.withLock { $0.totalListenedTo }
    }

    public func addTotalListeningTime(_ seconds: TimeInterval) {
        times.withLock { times in
            times.totalListenedTo += max(seconds, 0)
            times.isSynced = false
        }
    }

    // MARK: - total skipped

    public func totalSkippedTime() -> TimeInterval {
        times.withLock { $0.totalSkipped }
    }

    public func addSkippedTime(_ seconds: TimeInterval) {
        times.withLock { times in
            times.totalSkipped += max(seconds, 0)
            times.isSynced = false
        }
    }

    // MARK: - total auto skipped

    public func totalAutoSkippedTime() -> TimeInterval {
        times.withLock { $0.savedAutoSkipping }
    }

    public func addAutoSkipTime(_ seconds: TimeInterval) {
        times.withLock { times in
            times.savedAutoSkipping += max(seconds, 0)
            times.isSynced = false
        }
    }

    // MARK: - General

    /**
     * To conserve battery we want to keep these stats in memory. When it makes sense to, call this
     * method to actually save them between app launches.
     */
    public func persistTimes() {
        times.withLock { times in
            saveTime(times.savedDynamicSpeed, key: ServerConstants.UserDefaults.statsDynamicSpeedSeconds)
            saveTime(times.savedVariableSpeed, key: ServerConstants.UserDefaults.statsVariableSpeed)
            saveTime(times.totalListenedTo, key: ServerConstants.UserDefaults.statsListenedTo)
            saveTime(times.totalSkipped, key: ServerConstants.UserDefaults.statsSkipped)
            saveTime(times.savedAutoSkipping, key: ServerConstants.UserDefaults.statsAutoSkip)

            UserDefaults.standard.set(times.isSynced, forKey: ServerConstants.UserDefaults.statsSyncStatus)
        }
        UserDefaults.standard.synchronize()
    }

    public func syncStatus() -> SyncStatus {
        let isSynced = UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.statsSyncStatus)

        return isSynced ? SyncStatus.synced : SyncStatus.notSynced
    }

    public func setSyncStatus(_ syncStatus: SyncStatus) {
        let isSynced = (syncStatus == SyncStatus.synced)

        UserDefaults.standard.set(isSynced, forKey: ServerConstants.UserDefaults.statsSyncStatus)
    }

    // MARK: - Remote Stats

    public func loadRemoteStats(completion: ((Bool) -> Void)?) {
        ApiServerHandler.shared.loadStatsRequest { [weak self] remoteStats in
            guard let strongSelf = self, let remoteStats else {
                completion?(false)
                return
            }

            strongSelf.saveTime(remoteStats.silenceRemovalTime, key: ServerConstants.UserDefaults.statsDynamicSpeedSecondsServer)
            strongSelf.saveTime(remoteStats.totalListenTime, key: ServerConstants.UserDefaults.statsListenedToServer)
            strongSelf.saveTime(remoteStats.autoSkipTime, key: ServerConstants.UserDefaults.statsAutoSkipServer)
            strongSelf.saveTime(remoteStats.variableSpeedTime, key: ServerConstants.UserDefaults.statsVariableSpeedServer)
            strongSelf.saveTime(remoteStats.skipTime, key: ServerConstants.UserDefaults.statsSkippedServer)

            UserDefaults.standard.setValue(remoteStats.startedStatsAt, forKey: ServerConstants.UserDefaults.statsStartedDateServer)

            completion?(true)
        }
    }

    public func statsStartedAt() -> Int64 {
        Int64(UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.statsStartedDateServer))
    }

    public func statsStartDate() -> Date {
        if let startDate = UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.statsStartDate) as? Date {
            return startDate
        }

        let now = Date()
        UserDefaults.standard.set(now, forKey: ServerConstants.UserDefaults.statsStartDate)

        return now
    }

    public func timeSavedDynamicSpeedInclusive() -> TimeInterval {
        timeSavedDynamicSpeed() + timeForKey(ServerConstants.UserDefaults.statsDynamicSpeedSecondsServer)
    }

    public func timeSavedVariableSpeedInclusive() -> TimeInterval {
        timeSavedVariableSpeed() + timeForKey(ServerConstants.UserDefaults.statsVariableSpeedServer)
    }

    public func totalListeningTimeInclusive() -> TimeInterval {
        totalListeningTime() + timeForKey(ServerConstants.UserDefaults.statsListenedToServer)
    }

    public func totalSavedTime() -> TimeInterval {
        [
            totalSkippedTimeInclusive(),
            timeSavedVariableSpeedInclusive(),
            timeSavedDynamicSpeedInclusive(),
            totalAutoSkippedTimeInclusive()
        ].reduce(0, +)
    }

    public func totalSkippedTimeInclusive() -> TimeInterval {
        totalSkippedTime() + timeForKey(ServerConstants.UserDefaults.statsSkippedServer)
    }

    public func totalAutoSkippedTimeInclusive() -> TimeInterval {
        totalAutoSkippedTime() + timeForKey(ServerConstants.UserDefaults.statsAutoSkipServer)
    }

    // MARK: - Private Helpers

    private func parse(double: AnyObject?) -> Double {
        if let number = double as? Double {
            return number
        }
        if let number = double as? Int {
            return Double(number)
        }

        return 0
    }

    private func parse(integer: AnyObject?) -> Int64 {
        if let number = integer as? Int64 {
            return number
        }
        if let number = integer as? Int {
            return Int64(number)
        }

        return 0
    }

    private func timeForKey(_ key: String) -> TimeInterval {
        UserDefaults.standard.double(forKey: key)
    }

    private func saveTime(_ time: TimeInterval, key: String) {
        if time < 0, time < timeForKey(key) { return }

        UserDefaults.standard.set(time, forKey: key)
    }

    private func saveTime(_ time: Int64, key: String) {
        saveTime(TimeInterval(time), key: key)
    }
}
