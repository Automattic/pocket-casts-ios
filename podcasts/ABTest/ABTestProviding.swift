import AutomatticTracks

protocol ABTestProviding {
    func variation(for abTest: ABTest) -> Variation
    func start() async
}
