import AutomatticTracks

struct ABTestProvider: ABTestProviding {

    /// A singleton instance of the current provider
    static let shared = ABTestProvider()

    /// Returns the current variation for a given ab test. Users assigned to `control` and users ineligible for the experiment are given the assignment `null` which corresponds to them experiencing the `control` variation.
    /// - Parameter abTest: A given ab test
    /// - Returns: The variation in which a user is allocated
    func variation(for abTest: ABTest) -> Variation {
        ExPlat.shared.experiment(abTest.rawValue) ?? .control
    }

    /// Registers the experiments and refreshes `ExPlat`
    func start() async {
        await withCheckedContinuation { continuation in
            let experiments = ABTest.allCases.map { $0.rawValue }
            if experiments.isEmpty {
                return continuation.resume()
            }

            ExPlat.shared.register(experiments: experiments)
            ExPlat.shared.refresh {
                continuation.resume()
            }
        }
    }
    
    /// Reload the `ExPlat` instance
    /// - Parameters:
    ///   - platform: A given platform name
    ///   - oAuthToken: a WP Auth Token
    ///   - userAgent: A user agent
    ///   - anonId: The anonymous id
    func reloadExPlat(platform: String, oAuthToken: String? = nil, userAgent: String? = nil, anonId: String? = nil) {
        ExPlat.configure(platform: platform, oAuthToken: oAuthToken, userAgent: userAgent, anonId: anonId)
    }
}
