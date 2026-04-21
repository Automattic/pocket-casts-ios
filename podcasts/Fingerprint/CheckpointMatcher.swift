import Foundation

enum CheckpointMatcher {

    struct Match {
        let referenceStartIndex: Int
        let score: Float
    }

    static func findTopMatches(
        windowFingerprint: ReferenceFingerprint,
        reference: ReferenceFingerprint,
        maxResults: Int = 5
    ) -> [Match] {
        let windowCheckpoints = windowFingerprint.checkpoints
        let refCheckpoints = reference.checkpoints

        guard !windowCheckpoints.isEmpty, refCheckpoints.count >= windowCheckpoints.count else {
            return []
        }

        let windowData = windowCheckpoints.compactMap { Data(base64Encoded: $0.data) }
        let refData = refCheckpoints.compactMap { Data(base64Encoded: $0.data) }

        guard windowData.count == windowCheckpoints.count,
              refData.count == refCheckpoints.count else {
            return []
        }

        let windowCount = windowData.count
        let slidePositions = refData.count - windowCount + 1
        var matches: [Match] = []

        for offset in 0..<slidePositions {
            var totalScore: Float = 0
            for i in 0..<windowCount {
                totalScore += similarity(windowData[i], refData[offset + i])
            }
            let avgScore = totalScore / Float(windowCount)

            if avgScore >= FingerprintConstants.matchScoreThreshold {
                matches.append(Match(referenceStartIndex: offset, score: avgScore))
            }
        }

        matches.sort { $0.score > $1.score }
        return Array(matches.prefix(maxResults))
    }

    // MARK: - Private

    private static func similarity(_ a: Data, _ b: Data) -> Float {
        let count = min(a.count, b.count)
        guard count > 0 else { return 0 }

        var matchingBits = 0
        let totalBits = count * 8

        a.withUnsafeBytes { aPtr in
            b.withUnsafeBytes { bPtr in
                let aBytes = aPtr.bindMemory(to: UInt8.self)
                let bBytes = bPtr.bindMemory(to: UInt8.self)
                for i in 0..<count {
                    let xor = aBytes[i] ^ bBytes[i]
                    matchingBits += 8 - xor.nonzeroBitCount
                }
            }
        }

        return Float(matchingBits) / Float(totalBits)
    }
}
