import Foundation
import PocketCastsUtils
import SwiftProtobuf

// A series of methods to update between ApiSetting (server settings) and ModifiedDate (local) types

extension ApiSetting {
    /// Updates the `ApiSetting` instance with values from a `ModifiedDate`.
    /// - Parameter modified: A `ModifiedDate` instance which contains a value and (optional) modified date to set on this `ApiSetting`
    mutating func update(_ modified: ModifiedDate<ReturnValue.T>) {
        if let modifiedAt = modified.modifiedAt {
            self.modifiedAt = Google_Protobuf_Timestamp(date: modifiedAt)
            value.value = modified.wrappedValue
        }
    }

    /// Updates the `ApiSetting` instance with values from a `ModifiedDate`.
    /// - Parameter modified: A `ModifiedDate` instance which contains a value and (optional) modified date to set on this `ApiSetting`
    mutating func update<T: RawRepresentable<ReturnValue.T>>(_ modified: ModifiedDate<T>) {
        if let modifiedAt = modified.modifiedAt {
            self.modifiedAt = Google_Protobuf_Timestamp(date: modifiedAt)
            value.value = modified.wrappedValue.rawValue
        }
    }
}

extension ModifiedDate {
    /// Updates the ApiSetting ModifiedDate instance with values from an ApiSetting
    /// - Parameter setting: An `ApiSetting` instance which contains a value and (optional) modified date to set on this `ModifiedDate`
    mutating func update<S: ApiSetting>(setting: S) where Value == S.ReturnValue.T {
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        if setting.modifiedAt.date > modifiedAt ?? referenceDate {
            self = ModifiedDate(wrappedValue: setting.value.value)
        }
    }
}

extension ModifiedDate where Value: RawRepresentable {
    enum ApiUpdateError: Error {
        case representableNotFound(value: Any, representable: Value.Type)
    }
    
    /// Updates the ModifiedDate instance with values from an ApiSetting
    /// - Parameter setting: An `ApiSetting` instance which contains a value and (optional) modified date to set on this `ModifiedDate`
    mutating private func uncaughtUpdate<S: ApiSetting>(setting: S) throws where Value.RawValue == S.ReturnValue.T {
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        if setting.modifiedAt.date > modifiedAt ?? referenceDate {
            guard let value = Value(rawValue: setting.value.value) else {
                throw ApiUpdateError.representableNotFound(value: setting.value.value, representable: Value.self)
            }
            self = ModifiedDate(wrappedValue: value)
        }
    }

    /// Updates the ApiSetting ModifiedDate instance with values from an ApiSetting
    /// - Parameter setting: An `ApiSetting` instance which contains a value and (optional) modified date to set on this `ModifiedDate`
    mutating func update<S: ApiSetting>(setting: S) where Value.RawValue == S.ReturnValue.T {
        do {
            try uncaughtUpdate(setting: setting)
        } catch let error {
            switch error {
            case ApiUpdateError.representableNotFound(value: let value, representable: let representable):
                FileLog.shared.addMessage("Failed to represent value: \(value) representing: \(representable)")
            default:
                ()
            }
        }
    }
}
