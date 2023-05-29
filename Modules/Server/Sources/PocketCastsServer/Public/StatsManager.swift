import Foundation
import PocketCastsDataModel

public class StatsManager {
    public static let shared = StatsManager()

    private var savedDynamicSpeed = -1 as TimeInterval
    private var savedVariableSpeed = -1 as TimeInterval
    private var totalListenedTo = -1 as TimeInterval
    private var totalSkipped = -1 as TimeInterval
    private var savedAutoSkipping = -1 as TimeInterval

    private var isSynced = true
    private var updateQueue = DispatchQueue(label: "au.com.pocketcasts.StatsManagerQueue")

    public init() {
        if UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.statsStartDate) as? Date == nil {
            UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.statsStartDate)
            UserDefaults.standard.synchronize()
        }

        updateQueue.sync {
            savedDynamicSpeed = timeForKey(ServerConstants.UserDefaults.statsDynamicSpeedSeconds)
            savedVariableSpeed = timeForKey(ServerConstants.UserDefaults.statsVariableSpeed)
            totalListenedTo = timeForKey(ServerConstants.UserDefaults.statsListenedTo)
            totalSkipped = timeForKey(ServerConstants.UserDefaults.statsSkipped)
            savedAutoSkipping = timeForKey(ServerConstants.UserDefaults.statsAutoSkip)
        }
    }

    // MARK: - dynamic speed

    public func timeSavedDynamicSpeed() -> TimeInterval {
        savedDynamicSpeed
    }

    public func addTimeSavedDynamicSpeed(_ seconds: TimeInterval) {
        updateQueue.async { [weak self] in
            self?.savedDynamicSpeed += seconds
            self?.isSynced = false
        }
    }

    // MARK: - variable speed

    public func timeSavedVariableSpeed() -> TimeInterval {
        savedVariableSpeed
    }

    public func addTimeSavedVariableSpeed(_ seconds: TimeInterval) {
        updateQueue.async { [weak self] in
            self?.savedVariableSpeed += seconds
            self?.isSynced = false
        }
    }

    // MARK: - total listened

    public func totalListeningTime() -> TimeInterval {
        totalListenedTo
    }

    public func addTotalListeningTime(_ seconds: TimeInterval) {
        updateQueue.async { [weak self] in
            self?.totalListenedTo += seconds
            self?.isSynced = false
        }
    }

    // MARK: - total skipped

    public func totalSkippedTime() -> TimeInterval {
        totalSkipped
    }

    public func addSkippedTime(_ seconds: TimeInterval) {
        updateQueue.async { [weak self] in
            self?.totalSkipped += seconds
            self?.isSynced = false
        }
    }

    // MARK: - total auto skipped

    public func totalAutoSkippedTime() -> TimeInterval {
        savedAutoSkipping
    }

    public func addAutoSkipTime(_ seconds: TimeInterval) {
        updateQueue.async { [weak self] in
            self?.savedAutoSkipping += seconds
            self?.isSynced = false
        }
    }

    // MARK: - General

    /**
     * To conserve battery we want to keep these stats in memory. When it makes sense to, call this
     * method to actually save them between app launches.
     */
    public func persistTimes() {
        updateQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.saveTime(strongSelf.savedDynamicSpeed, key: ServerConstants.UserDefaults.statsDynamicSpeedSeconds)
            strongSelf.saveTime(strongSelf.savedVariableSpeed, key: ServerConstants.UserDefaults.statsVariableSpeed)
            strongSelf.saveTime(strongSelf.totalListenedTo, key: ServerConstants.UserDefaults.statsListenedTo)
            strongSelf.saveTime(strongSelf.totalSkipped, key: ServerConstants.UserDefaults.statsSkipped)
            strongSelf.saveTime(strongSelf.savedAutoSkipping, key: ServerConstants.UserDefaults.statsAutoSkip)

            UserDefaults.standard.set(strongSelf.isSynced, forKey: ServerConstants.UserDefaults.statsSyncStatus)
            UserDefaults.standard.synchronize()
        }
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
            guard let strongSelf = self, let remoteStats = remoteStats else { return }

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
        if time < 0 { return }

        UserDefaults.standard.set(time, forKey: key)
    }

    private func saveTime(_ time: Int64, key: String) {
        saveTime(TimeInterval(time), key: key)
    }
}
