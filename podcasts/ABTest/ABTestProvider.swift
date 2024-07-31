import AutomatticTracks

struct ABTestProvider: ABTestProviding {
    static let shared = ABTestProvider()

    private let exPlat: ExPlat

    init(exPlat: ExPlat = ExPlat.shared) {
        self.exPlat = exPlat
    }

    func variation(for abTest: ABTest) -> Variation {
        exPlat.experiment(abTest.rawValue) ?? .control
    }

    func start() async {
        await withCheckedContinuation { continuation in
            let experiments = ABTest.allCases.map { $0.rawValue }
            if experiments.isEmpty {
                return continuation.resume()
            }

            exPlat.register(experiments: experiments)
            exPlat.refresh {
                continuation.resume()
            }
        }
    }
}
