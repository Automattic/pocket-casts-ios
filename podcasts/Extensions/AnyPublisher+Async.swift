import Combine

extension AnyPublisher where Failure == Never {
    func awaitFirstValue(in set: inout Set<AnyCancellable>) async -> Output {
        return await withCheckedContinuation { continuation in
            self
                .first()
                .sink { value in
                    continuation.resume(returning: value)
                }
                .store(in: &set)
        }
    }
}

extension AnyPublisher {
    func awaitFirstValue(in set: inout Set<AnyCancellable>) async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .first()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        ()
                    }
                }, receiveValue: { value in
                    continuation.resume(returning: value)
                })
                .store(in: &set)
        }
    }
}
