import AutomatticTracks

struct ABTestProvider: ABTestProviding {
    static let shared = ABTestProvider()

    func variation(for abTest: ABTest) -> Variation {
        ExPlat.shared.experiment(abTest.rawValue) ?? .control
    }

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

    func reloadExPlat(platform: String, oAuthToken: String? = nil, userAgent: String? = nil, anonId: String? = nil) {
        ExPlat.configure(platform: platform, oAuthToken: oAuthToken, userAgent: userAgent, anonId: anonId)
    }
}
