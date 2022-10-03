import DataModel
import Foundation
import SwiftProtobuf
import Utils

class RetrieveStatsTask: ApiBaseTask {
    var completion: ((RemoteStats?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/stats/summary"

        do {
            var statsRequest = Api_StatsRequest()
            statsRequest.deviceID = Settings.uniqueAppId() ?? ""
            statsRequest.deviceType = Constants.Values.deviceTypeiOS
            let data = try statsRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let result = try Api_StatsResponse(serializedData: responseData)

                let remoteStats = RemoteStats(silenceRemovalTime: result.timeSilenceRemoval,
                                              totalListenTime: result.timeListened,
                                              autoSkipTime: result.timeIntroSkipping,
                                              variableSpeedTime: result.timeVariableSpeed,
                                              skipTime: result.timeSkipping,
                                              startedStatsAt: result.timesStartedAt.seconds)
                completion?(remoteStats)
            } catch {
                FileLog.shared.addMessage("Failed to retrieve remote stats \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("Failed to encode remote stats \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
