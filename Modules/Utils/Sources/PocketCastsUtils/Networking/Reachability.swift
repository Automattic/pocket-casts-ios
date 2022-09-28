/*
 Copyright (c) 2014, Ashley Mills
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#if !os(watchOS)
    import Foundation
    import SystemConfiguration

    class Reachability {
        private typealias NetworkReachable = (Reachability) -> Void
        private typealias NetworkUnreachable = (Reachability) -> Void

        @available(*, unavailable, renamed: "Connection")
        private enum NetworkStatus: CustomStringConvertible {
            case notReachable, reachableViaWiFi, reachableViaWWAN
            public var description: String {
                switch self {
                case .reachableViaWWAN: return "Cellular"
                case .reachableViaWiFi: return "WiFi"
                case .notReachable: return "No Connection"
                }
            }
        }

        enum Connection: CustomStringConvertible {
            case none, wifi, cellular
            public var description: String {
                switch self {
                case .cellular: return "Cellular"
                case .wifi: return "WiFi"
                case .none: return "No Connection"
                }
            }
        }

        private var whenReachable: NetworkReachable?
        private var whenUnreachable: NetworkUnreachable?

        /// Set to `false` to force Reachability.connection to .none when on cellular connection (default value `true`)
        private var allowsCellularConnection: Bool

        var connection: Connection {
            guard isReachableFlagSet else { return .none }

            // If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
            guard isRunningOnDevice else { return .wifi }

            var connection = Connection.none

            if !isConnectionRequiredFlagSet {
                connection = .wifi
            }

            if isConnectionOnTrafficOrDemandFlagSet {
                if !isInterventionRequiredFlagSet {
                    connection = .wifi
                }
            }

            if isOnWWANFlagSet {
                if !allowsCellularConnection {
                    connection = .none
                } else {
                    connection = .cellular
                }
            }

            return connection
        }

        private var isRunningOnDevice: Bool = {
            #if targetEnvironment(simulator)
                return false
            #else
                return true
            #endif
        }()

        private let reachabilityRef: SCNetworkReachability
        private var usingHostname = false

        required init(reachabilityRef: SCNetworkReachability, usingHostname: Bool = false) {
            allowsCellularConnection = true
            self.reachabilityRef = reachabilityRef
            self.usingHostname = usingHostname
        }

        convenience init?(hostname: String) {
            guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
            self.init(reachabilityRef: ref, usingHostname: true)
        }

        convenience init?() {
            var zeroAddress = sockaddr()
            zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
            zeroAddress.sa_family = sa_family_t(AF_INET)

            guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else { return nil }

            self.init(reachabilityRef: ref)
        }
    }

    private extension Reachability {
        var isOnWWANFlagSet: Bool {
            #if os(iOS)
                return flags.contains(.isWWAN)
            #else
                return false
            #endif
        }

        var isReachableFlagSet: Bool {
            flags.contains(.reachable)
        }

        var isConnectionRequiredFlagSet: Bool {
            flags.contains(.connectionRequired)
        }

        var isInterventionRequiredFlagSet: Bool {
            flags.contains(.interventionRequired)
        }

        var isConnectionOnTrafficFlagSet: Bool {
            flags.contains(.connectionOnTraffic)
        }

        var isConnectionOnDemandFlagSet: Bool {
            flags.contains(.connectionOnDemand)
        }

        var isConnectionOnTrafficOrDemandFlagSet: Bool {
            !flags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
        }

        var isTransientConnectionFlagSet: Bool {
            flags.contains(.transientConnection)
        }

        var isLocalAddressFlagSet: Bool {
            flags.contains(.isLocalAddress)
        }

        var isDirectFlagSet: Bool {
            flags.contains(.isDirect)
        }

        var isConnectionRequiredAndTransientFlagSet: Bool {
            flags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
        }

        var flags: SCNetworkReachabilityFlags {
            var flags = SCNetworkReachabilityFlags()
            if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {
                return flags
            } else {
                return SCNetworkReachabilityFlags()
            }
        }
    }
#endif
