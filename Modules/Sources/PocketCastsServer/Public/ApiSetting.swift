import SwiftProtobuf

/// A server setting which contains a modified date and value
protocol ApiSetting {
    associatedtype ReturnValue: ApiReturnValue
    var modifiedAt: Google_Protobuf_Timestamp { get set }
    var value: ReturnValue { get set }
}

/// A generic type representing all Protobuf types with an initializer and value (like Bool, String, Int32)
protocol ApiReturnValue {
    associatedtype T: Codable, Equatable
    init(_: T)
    var value: T { get set }
}

extension Api_BoolSetting: ApiSetting {}
extension Api_Int32Setting: ApiSetting {}
extension Api_DoubleSetting: ApiSetting {}
extension Api_StringSetting: ApiSetting {}

extension Google_Protobuf_BoolValue: ApiReturnValue { }
extension Google_Protobuf_Int32Value: ApiReturnValue { }
extension Google_Protobuf_DoubleValue: ApiReturnValue { }
extension Google_Protobuf_StringValue: ApiReturnValue { }
